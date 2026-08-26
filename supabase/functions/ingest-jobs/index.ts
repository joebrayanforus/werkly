import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type IncomingJob = {
  externalId: string
  title: string
  company: string
  location: string
  latitude?: number
  longitude?: number
  remoteType?: 'onsite' | 'hybrid' | 'remote'
  salaryMin?: number
  salaryMax?: number
  source: 'LinkedIn' | 'Indeed' | 'StepStone'
  sourceUrl: string
  tags?: string[]
  description?: string
  postedAt?: string
  expiresAt?: string
}

const allowedHosts: Record<IncomingJob['source'], string[]> = {
  LinkedIn: ['linkedin.com'],
  Indeed: ['indeed.com'],
  StepStone: ['stepstone.de', 'stepstone.com'],
}

function trustedSourceUrl(source: IncomingJob['source'], value: string) {
  try {
    const url = new URL(value)
    return url.protocol === 'https:' && allowedHosts[source].some(
      (host) => url.hostname === host || url.hostname.endsWith(`.${host}`),
    )
  } catch {
    return false
  }
}

async function tokenMatches(provided: string, expected: string) {
  const encoder = new TextEncoder()
  const [providedHash, expectedHash] = await Promise.all([
    crypto.subtle.digest('SHA-256', encoder.encode(provided)),
    crypto.subtle.digest('SHA-256', encoder.encode(expected)),
  ])
  const left = new Uint8Array(providedHash)
  const right = new Uint8Array(expectedHash)
  return left.length === right.length && left.every((byte, index) => byte === right[index])
}

function decodeHtmlEntities(value: string) {
  const named: Record<string, string> = {
    nbsp: ' ', amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", '#39': "'",
    ndash: '–', mdash: '—', hellip: '…', bull: '•', middot: '·',
    auml: 'ä', ouml: 'ö', uuml: 'ü', Auml: 'Ä', Ouml: 'Ö', Uuml: 'Ü', szlig: 'ß',
  }
  return value.replace(/&(#x?[0-9a-f]+|[a-z][a-z0-9]+);/gi, (original, entity: string) => {
    if (named[entity] != null) return named[entity]
    const codePoint = entity.toLowerCase().startsWith('#x')
      ? Number.parseInt(entity.slice(2), 16)
      : entity.startsWith('#') ? Number.parseInt(entity.slice(1), 10) : Number.NaN
    return Number.isFinite(codePoint) && codePoint > 0 && codePoint <= 0x10ffff
      ? String.fromCodePoint(codePoint)
      : original
  })
}

function cleanPartnerText(value: unknown, preserveParagraphs = false) {
  if (typeof value !== 'string') return ''
  let result = value
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<!--[\s\S]*?-->/g, '')
  if (preserveParagraphs) {
    result = result
      .replace(/<\s*br\s*\/?\s*>/gi, '\n')
      .replace(/<\s*li\b[^>]*>/gi, '\n• ')
      .replace(/<\s*\/\s*(?:p|div|li|h[1-6]|section|article|tr|ul|ol)\s*>/gi, '\n')
  }
  result = decodeHtmlEntities(result.replace(/<[^>]*>/g, ''))
  return preserveParagraphs
    ? result.replace(/[ \t]+\n/g, '\n').replace(/\n[ \t]+/g, '\n')
      .replace(/[ \t]{2,}/g, ' ').replace(/\n{3,}/g, '\n\n')
      .replace(/\n{2,}(?=• )/g, '\n').trim()
    : result.replace(/\s+/g, ' ').trim()
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405 })
  }

  const expectedToken = Deno.env.get('JOB_INGEST_TOKEN')
  const providedToken = request.headers.get('x-werkly-ingest-token') ?? ''
  if (!expectedToken) {
    return Response.json({ error: 'Job ingestion is not configured' }, { status: 503 })
  }
  if (!providedToken || !(await tokenMatches(providedToken, expectedToken))) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  let payload: { jobs?: IncomingJob[] }
  try {
    payload = await request.json()
  } catch {
    return Response.json({ error: 'Invalid JSON payload' }, { status: 400 })
  }

  if (!Array.isArray(payload.jobs) || payload.jobs.length === 0 || payload.jobs.length > 500) {
    return Response.json({ error: 'Provide between 1 and 500 jobs' }, { status: 400 })
  }

  const rows = []
  for (const job of payload.jobs) {
    if (!job.externalId?.trim() || !job.title?.trim() || !job.company?.trim() ||
      !job.location?.trim() || !allowedHosts[job.source] ||
      !trustedSourceUrl(job.source, job.sourceUrl)) {
      return Response.json(
        { error: `Invalid job from ${job.source ?? 'unknown source'}` },
        { status: 400 },
      )
    }
    if (job.latitude != null && (job.latitude < -90 || job.latitude > 90)) {
      return Response.json({ error: 'Invalid latitude' }, { status: 400 })
    }
    if (job.longitude != null && (job.longitude < -180 || job.longitude > 180)) {
      return Response.json({ error: 'Invalid longitude' }, { status: 400 })
    }

    rows.push({
      external_id: job.externalId.trim().slice(0, 250),
      title: cleanPartnerText(job.title).slice(0, 300),
      company: cleanPartnerText(job.company).slice(0, 250),
      location: cleanPartnerText(job.location).slice(0, 300),
      latitude: job.latitude ?? null,
      longitude: job.longitude ?? null,
      remote_type: job.remoteType ?? 'onsite',
      salary_min: job.salaryMin ?? null,
      salary_max: job.salaryMax ?? null,
      source: job.source,
      source_url: job.sourceUrl,
      tags: (job.tags ?? []).slice(0, 20)
        .map((tag) => cleanPartnerText(tag).slice(0, 60)).filter(Boolean),
      description: cleanPartnerText(job.description, true).slice(0, 20_000),
      posted_at: job.postedAt ?? new Date().toISOString(),
      expires_at: job.expiresAt ?? null,
      active: true,
    })
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  const { error } = await admin.from('jobs').upsert(rows, {
    onConflict: 'source,external_id',
  })

  if (error) return Response.json({ error: error.message }, { status: 500 })
  return Response.json({ imported: rows.length })
})
