import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.2'
import webpush from 'npm:web-push@3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Same public key hardcoded in web/index.html -- not secret, sent to every
// subscribing browser anyway, so duplicating the literal here (rather than
// wiring another shared config layer) is the simplest correct option.
const VAPID_PUBLIC_KEY = 'BN-D2VNVVkm7fiw9L6dSJrxAdaTh6kWLuAMKIPC_VGqhi2NSLrs_iBZpQdN6-MPmZ5kAvpFLHw7-wAggW7-xvHM'

const MAX_NOTIFICATIONS_PER_USER = 3

type PushSubscriptionRow = { user_id: string; endpoint: string; p256dh: string; auth: string }
type ProfileRow = { id: string; city: string; skills: unknown }
type JobRow = {
  id: number
  title: string
  company: string
  location: string
  tags: string[] | null
  remote_type: string
}

// Supabase projects on the newer key system issue an opaque `sb_secret_...`
// service key instead of a JWT -- sync-free-jobs already resolves exactly
// this value as `adminKey` and hands it here as a bearer token, so it must
// be accepted directly, not decoded as a JWT. A legacy JWT-format service
// role key (with a `role` claim) is still accepted as a fallback for
// projects that haven't migrated.
function isServiceRoleRequest(authorization: string): boolean {
  const token = authorization.replace(/^Bearer\s+/i, '').trim()
  if (!token) return false

  let secretKeys: Record<string, string> = {}
  try {
    secretKeys = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}')
  } catch {
    // Ignore a malformed or absent env value.
  }
  if (Object.values(secretKeys).includes(token)) return true
  if (token === Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) return true

  try {
    const payload = token.split('.')[1]
    const json = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')))
    return json.role === 'service_role'
  } catch {
    return false
  }
}

function normalize(value: string) {
  return value.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim()
}

function profileSkillNames(rawSkills: unknown): string[] {
  if (!Array.isArray(rawSkills)) return []
  return rawSkills.flatMap((entry) => {
    if (typeof entry === 'string') return [entry]
    if (entry && typeof entry === 'object' && typeof (entry as { name?: unknown }).name === 'string') {
      return [(entry as { name: string }).name]
    }
    return []
  })
}

function jobMatchesProfile(job: JobRow, profile: ProfileRow): boolean {
  const city = normalize(profile.city ?? '')
  const locationFits =
    job.remote_type !== 'onsite' ||
    city.length === 0 ||
    normalize(job.location).includes(city)
  if (!locationFits) return false

  const profileSkills = profileSkillNames(profile.skills).map(normalize).filter(Boolean)
  if (profileSkills.length === 0) return false
  const jobTags = (job.tags ?? []).map(normalize).filter(Boolean)
  return jobTags.some((tag) => profileSkills.some((skill) => tag.includes(skill) || skill.includes(tag)))
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders })
  }

  const authorization = request.headers.get('Authorization') ?? ''
  // No gateway JWT check (verify_jwt: false) since the caller presents an
  // opaque secret key, not a JWT -- this app-level check is the only auth,
  // and it restricts the caller to server-to-server calls from
  // sync-free-jobs, never an end user.
  if (!isServiceRoleRequest(authorization)) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders })
  }

  const vapidPrivateKey = Deno.env.get('VAPID_PRIVATE_KEY')?.trim()
  const vapidSubject = Deno.env.get('VAPID_SUBJECT')?.trim()
  if (!vapidPrivateKey || !vapidSubject) {
    return Response.json({ error: 'Push notifications are not configured yet' }, {
      status: 503,
      headers: corsHeaders,
    })
  }
  webpush.setVapidDetails(vapidSubject, VAPID_PUBLIC_KEY, vapidPrivateKey)

  let jobIds: number[] = []
  try {
    const body = await request.json() as { jobIds?: unknown }
    jobIds = Array.isArray(body.jobIds)
      ? body.jobIds.filter((id): id is number => Number.isFinite(id)).slice(0, 500)
      : []
  } catch {
    return Response.json({ error: 'Invalid JSON payload' }, { status: 400, headers: corsHeaders })
  }
  if (jobIds.length === 0) {
    return Response.json({ sent: 0, reason: 'no new jobs' }, { headers: corsHeaders })
  }

  let secretKeys: Record<string, string> = {}
  try {
    secretKeys = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}')
  } catch {
    // Ignore a malformed or absent env value.
  }
  const serviceRoleKey = (secretKeys.default ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'))?.trim()
  const url = Deno.env.get('SUPABASE_URL')?.trim()
  if (!serviceRoleKey || !url) {
    return Response.json({ error: 'Server configuration missing' }, { status: 503, headers: corsHeaders })
  }
  const admin = createClient(url, serviceRoleKey)

  const [{ data: jobs, error: jobsError }, { data: subscriptions, error: subscriptionsError }] =
    await Promise.all([
      admin.from('jobs').select('id, title, company, location, tags, remote_type').in('id', jobIds),
      admin.from('push_subscriptions').select('user_id, endpoint, p256dh, auth'),
    ])
  if (jobsError || subscriptionsError) {
    console.error('notify-job-matches read failed', jobsError, subscriptionsError)
    return Response.json({ error: 'Could not load jobs or subscriptions' }, {
      status: 502,
      headers: corsHeaders,
    })
  }
  const jobRows = (jobs ?? []) as JobRow[]
  const subscriptionRows = (subscriptions ?? []) as PushSubscriptionRow[]
  if (jobRows.length === 0 || subscriptionRows.length === 0) {
    return Response.json({ sent: 0, reason: 'nothing to match against' }, { headers: corsHeaders })
  }

  const userIds = [...new Set(subscriptionRows.map((row) => row.user_id))]
  const { data: profiles, error: profilesError } = await admin
    .from('profiles')
    .select('id, city, skills')
    .in('id', userIds)
  if (profilesError) {
    console.error('notify-job-matches profile read failed', profilesError)
    return Response.json({ error: 'Could not load profiles' }, { status: 502, headers: corsHeaders })
  }
  const profileById = new Map((profiles ?? []).map((row) => [row.id, row as ProfileRow]))

  const { data: alreadySent, error: sentError } = await admin
    .from('job_push_notifications_sent')
    .select('user_id, job_id')
    .in('job_id', jobIds)
    .in('user_id', userIds)
  if (sentError) console.error('notify-job-matches dedup read failed', sentError)
  const sentPairs = new Set((alreadySent ?? []).map((row) => `${row.user_id}:${row.job_id}`))

  const subscriptionsByUser = new Map<string, PushSubscriptionRow[]>()
  for (const row of subscriptionRows) {
    subscriptionsByUser.set(row.user_id, [...(subscriptionsByUser.get(row.user_id) ?? []), row])
  }

  let sent = 0
  const staleEndpoints: string[] = []
  const newlySent: Array<{ user_id: string; job_id: number }> = []

  for (const userId of userIds) {
    const profile = profileById.get(userId)
    if (!profile) continue
    const matches = jobRows
      .filter((job) => !sentPairs.has(`${userId}:${job.id}`) && jobMatchesProfile(job, profile))
      .slice(0, MAX_NOTIFICATIONS_PER_USER)
    if (matches.length === 0) continue

    for (const job of matches) {
      const payload = JSON.stringify({
        title: `New match: ${job.title}`,
        body: `${job.company} · ${job.location}`,
        jobId: job.id,
      })
      let deliveredToAnySubscription = false
      for (const subscription of subscriptionsByUser.get(userId) ?? []) {
        try {
          await webpush.sendNotification(
            {
              endpoint: subscription.endpoint,
              keys: { p256dh: subscription.p256dh, auth: subscription.auth },
            },
            payload,
          )
          deliveredToAnySubscription = true
        } catch (error) {
          const statusCode = (error as { statusCode?: number })?.statusCode
          if (statusCode === 404 || statusCode === 410) {
            staleEndpoints.push(subscription.endpoint)
          } else {
            console.error('web-push send failed', statusCode, error)
          }
        }
      }
      if (deliveredToAnySubscription) {
        sent++
        newlySent.push({ user_id: userId, job_id: job.id })
      }
    }
  }

  if (staleEndpoints.length > 0) {
    await admin.from('push_subscriptions').delete().in('endpoint', staleEndpoints)
  }
  if (newlySent.length > 0) {
    await admin.from('job_push_notifications_sent').upsert(newlySent, {
      onConflict: 'user_id,job_id',
    })
  }

  return Response.json({ sent, staleRemoved: staleEndpoints.length }, { headers: corsHeaders })
})
