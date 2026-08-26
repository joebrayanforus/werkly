import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type JobRow = {
  external_id: string
  title: string
  company: string
  location: string
  latitude: number | null
  longitude: number | null
  remote_type: 'onsite' | 'hybrid' | 'remote'
  salary_min: number | null
  salary_max: number | null
  source: string
  source_url: string
  tags: string[]
  description: string
  posted_at: string
  expires_at: string | null
  active: boolean
}

type BaJob = {
  stellenangebotsTitel?: string
  firma?: string
  referenznummer?: string
  stellenlokationen?: Array<{
    adresse?: { ort?: string; region?: string }
    breite?: number
    laenge?: number
  }>
  homeofficemoeglich?: boolean
  externeURL?: string
  hauptberuf?: string
  alleBerufe?: string[]
  datumErsteVeroeffentlichung?: string
  aenderungsdatum?: string
}

type GreenhouseJob = {
  id?: number
  title?: string
  updated_at?: string
  location?: { name?: string }
  absolute_url?: string
  content?: string
  departments?: Array<{ name?: string }>
}

type LeverJob = {
  id?: string
  text?: string
  createdAt?: number
  descriptionPlain?: string
  additionalPlain?: string
  hostedUrl?: string
  country?: string
  workplaceType?: string
  categories?: {
    commitment?: string
    department?: string
    location?: string
    team?: string
  }
}

type AdzunaJob = {
  id?: string
  title?: string
  description?: string
  created?: string
  redirect_url?: string
  latitude?: number
  longitude?: number
  company?: { display_name?: string }
  location?: { display_name?: string }
  category?: { label?: string }
}

type ArbeitnowJob = {
  slug?: string
  company_name?: string
  title?: string
  description?: string
  remote?: boolean
  url?: string
  tags?: string[]
  job_types?: string[]
  location?: string
  created_at?: number
}

type SmartRecruitersPosting = {
  id?: string
  name?: string
  releasedDate?: string
  company?: { identifier?: string; name?: string }
  location?: {
    city?: string
    region?: string
    country?: string
    fullLocation?: string
    remote?: boolean
    hybrid?: boolean
    latitude?: string
    longitude?: string
  }
  industry?: { label?: string }
  department?: { label?: string }
  function?: { label?: string }
  typeOfEmployment?: { label?: string }
}

type SmartRecruitersPostingDetail = SmartRecruitersPosting & {
  postingUrl?: string
  applyUrl?: string
  active?: boolean
  jobAd?: {
    sections?: Record<string, { title?: string; text?: string }>
  }
}

type ProviderMetrics = {
  status: 'ok' | 'cached' | 'unavailable' | 'not_configured' | 'failed'
  fetched: number
  eligible: number
  deduplicated: number
  imported: number
  error?: string
}

const greenhouseBoards = [
  { token: 'sumup', company: 'SumUp' },
  { token: 'celonis', company: 'Celonis' },
]

const leverSites = [
  { site: 'justwatch', company: 'JustWatch', host: 'api.lever.co' },
  { site: 'quantco-', company: 'QuantCo', host: 'api.lever.co' },
  { site: 'netlight', company: 'Netlight', host: 'api.lever.co' },
  { site: 'sportalliance', company: 'Sport Alliance', host: 'api.eu.lever.co' },
  { site: 'Packmatic', company: 'Packmatic', host: 'api.lever.co' },
  { site: 'octoenergy', company: 'Octopus Energy', host: 'api.lever.co' },
  { site: 'finn', company: 'FINN', host: 'api.lever.co' },
]

// Public Posting API identifiers found on the employers' official career pages.
// Keeping an explicit allowlist avoids crawling company identifiers or private data.
const smartRecruitersCompanies = [
  { identifier: 'Redcare-Pharmacy', company: 'Redcare Pharmacy' },
  { identifier: 'AbbVie', company: 'AbbVie' },
  { identifier: 'ScalableGmbH', company: 'Scalable Capital' },
  { identifier: 'Vattenfall', company: 'Vattenfall' },
  { identifier: 'robertboschkrankenhausgmbh', company: 'Robert Bosch Krankenhaus' },
]

const cityCoordinates: Array<[RegExp, number, number]> = [
  [/berlin/i, 52.5200, 13.4050],
  [/munich|münchen/i, 48.1374, 11.5755],
  [/hamburg/i, 53.5511, 9.9937],
  [/frankfurt/i, 50.1109, 8.6821],
  [/karlsruhe/i, 49.0069, 8.4037],
  [/cologne|köln/i, 50.9375, 6.9603],
  [/düsseldorf|duesseldorf/i, 51.2277, 6.7735],
  [/stuttgart/i, 48.7758, 9.1829],
  [/leipzig/i, 51.3397, 12.3731],
  [/dresden/i, 51.0504, 13.7373],
  [/bonn/i, 50.7374, 7.0982],
  [/münster|muenster/i, 51.9607, 7.6261],
  [/nürnberg|nuremberg/i, 49.4521, 11.0767],
]

function envJson(name: string) {
  try {
    return JSON.parse(Deno.env.get(name) ?? '{}') as Record<string, string>
  } catch {
    return {}
  }
}

function isPublishableRequest(request: Request) {
  const provided = request.headers.get('apikey') ?? ''
  const keys = Object.values(envJson('SUPABASE_PUBLISHABLE_KEYS'))
  const legacy = Deno.env.get('SUPABASE_ANON_KEY')
  return provided.length > 0 && (keys.includes(provided) || provided === legacy)
}

function text(value: unknown, fallback = '') {
  return typeof value === 'string' ? value.trim() : fallback
}

function trustedHttps(value: unknown, fallback = '') {
  if (typeof value === 'string') {
    try {
      const url = new URL(value)
      if (url.protocol === 'https:') return url.toString()
    } catch {
      // Ignore malformed URLs from external feeds.
    }
  }
  return fallback
}

function decodeHtmlEntities(value: string) {
  const named: Record<string, string> = {
    nbsp: ' ', amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", '#39': "'",
    ndash: '–', mdash: '—', hellip: '…', bull: '•', middot: '·',
    auml: 'ä', ouml: 'ö', uuml: 'ü', Auml: 'Ä', Ouml: 'Ö', Uuml: 'Ü', szlig: 'ß',
  }
  return value.replace(/&(#x?[0-9a-f]+|[a-z][a-z0-9]+);/gi, (original, entity: string) => {
    const replacement = named[entity] ?? named[entity.toLowerCase()]
    if (replacement != null) return replacement
    const codePoint = entity.toLowerCase().startsWith('#x')
      ? Number.parseInt(entity.slice(2), 16)
      : entity.startsWith('#') ? Number.parseInt(entity.slice(1), 10) : Number.NaN
    return Number.isFinite(codePoint) && codePoint > 0 && codePoint <= 0x10ffff
      ? String.fromCodePoint(codePoint)
      : original
  })
}

function stripHtml(value: unknown) {
  let result = text(value)
  // Some feeds encode an entire HTML fragment as entities. Two passes remove
  // both ordinary tags and those revealed after entity decoding.
  for (let pass = 0; pass < 2; pass++) {
    result = result
      .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, ' ')
      .replace(/<!--([\s\S]*?)-->/g, ' ')
      .replace(/<\s*br\s*\/?\s*>/gi, '\n')
      .replace(/<\s*li\b[^>]*>/gi, '\n• ')
      .replace(/<\s*\/\s*(?:p|div|li|h[1-6]|section|article|ul|ol)\s*>/gi, '\n')
      .replace(/<[^>]+>/g, ' ')
    result = decodeHtmlEntities(result)
  }
  return result
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n[ \t]+/g, '\n')
    .replace(/[ \t]{2,}/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim()
}

function studentRole(...values: unknown[]) {
  return /werkstudent|working[ -]student|studentische|student assistant|student employee|hilfskraft|\bhiwi\b/i.test(
    values.map((value) => text(value)).join(' '),
  )
}

function germanyLocation(location: string, country = '') {
  return country.toUpperCase() === 'DE' ||
    /germany|deutschland|berlin|munich|münchen|hamburg|frankfurt|karlsruhe|cologne|köln|düsseldorf|duesseldorf|stuttgart|leipzig|dresden|bonn|münster|muenster|nuremberg|nürnberg|augsburg|bielefeld|bochum|bremen|darmstadt|dortmund|duisburg|erfurt|essen|freiburg|göttingen|goettingen|hannover|hanover|heidelberg|ingolstadt|jena|kiel|koblenz|lübeck|luebeck|mainz|mannheim|potsdam|regensburg|rostock|saarbrücken|saarbruecken|ulm|wiesbaden|würzburg|wuerzburg|baden-württemberg|baden-wuerttemberg|bavaria|bayern|brandenburg|hesse|hessen|lower saxony|niedersachsen|north rhine-westphalia|nordrhein-westfalen|rhineland-palatinate|rheinland-pfalz|saxony|sachsen|saxony-anhalt|sachsen-anhalt|schleswig-holstein|thuringia|thüringen|thueringen/i
      .test(location)
}

function coordinates(location: string): [number | null, number | null] {
  const match = cityCoordinates.find(([pattern]) => pattern.test(location))
  return match ? [match[1], match[2]] : [null, null]
}

function finiteNumber(value: unknown) {
  const parsed = typeof value === 'number' ? value : Number.parseFloat(text(value))
  return Number.isFinite(parsed) ? parsed : null
}

function recentEnough(value: string | undefined, days = 120) {
  if (!value) return true
  const date = new Date(value)
  return !Number.isNaN(date.getTime()) &&
    date.getTime() >= Date.now() - days * 24 * 60 * 60 * 1000
}

function fingerprintPart(value: string) {
  return value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\b(germany|deutschland|gmbh|mbh|ag|se|co|kg)\b/g, ' ')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
}

function jobFingerprint(row: JobRow) {
  const city = row.location.split(/[·,|/]/)[0]
  return [row.title, row.company, city].map(fingerprintPart).join('|')
}

function sourcePriority(source: string) {
  if (source.startsWith('Greenhouse ·') || source.startsWith('Lever ·') ||
    source === 'SmartRecruiters') return 0
  if (source === 'Bundesagentur für Arbeit') return 1
  if (source === 'Arbeitnow') return 2
  if (source === 'Adzuna') return 3
  return 4
}

function remoteType(location: string, value = ''): 'onsite' | 'hybrid' | 'remote' {
  const combined = `${location} ${value}`.toLowerCase()
  if (combined.includes('remote') && !combined.includes('hybrid')) return 'remote'
  if (combined.includes('hybrid') || combined.includes('teilweise home')) return 'hybrid'
  return 'onsite'
}

function skills(title: string, description: string, extras: string[] = []) {
  const combined = `${title} ${description}`.toLowerCase()
  const known = [
    ['Python', /python/],
    ['Data', /data|analytics|analyse/],
    ['AI', /\bai\b|artificial intelligence|künstliche intelligenz/],
    ['Product', /product/],
    ['Marketing', /marketing|seo|campaign/],
    ['Software', /software|developer|engineer|entwicklung/],
    ['Legal', /legal|recht/],
    ['HR', /human resources|people ops|payroll|personalwesen/],
    ['Sales', /sales|vertrieb|business development/],
    ['Finance', /finance|accounting|controlling/],
    ['Operations', /operations|betrieb/],
  ] as const
  return [...extras, ...known.filter(([, pattern]) => pattern.test(combined)).map(([label]) => label)]
    .map((item) => text(item).slice(0, 80))
    .filter((item, index, all) => item.length > 0 && all.indexOf(item) === index)
    .slice(0, 10)
}

async function fetchBundesagentur(): Promise<JobRow[]> {
  const endpoint = new URL('https://rest.arbeitsagentur.de/jobboerse/jobsuche-service/pc/v6/jobs')
  endpoint.searchParams.set('was', 'Werkstudent')
  endpoint.searchParams.set('wo', 'Deutschland')
  endpoint.searchParams.set('umkreis', '200')
  endpoint.searchParams.set('page', '1')
  endpoint.searchParams.set('size', '100')
  const response = await fetch(endpoint, {
    headers: { 'X-API-Key': 'jobboerse-jobsuche', Accept: 'application/json' },
    signal: AbortSignal.timeout(12_000),
  })
  if (!response.ok) throw new Error(`Bundesagentur ${response.status}`)
  const payload = await response.json() as { ergebnisliste?: BaJob[] }
  if (!Array.isArray(payload.ergebnisliste)) throw new Error('Bundesagentur malformed response')
  return payload.ergebnisliste.flatMap((job) => {
    const reference = text(job.referenznummer)
    const title = text(job.stellenangebotsTitel)
    const company = text(job.firma)
    const place = job.stellenlokationen?.[0]
    if (!reference || !title || !company || !place) return []
    const city = text(place.adresse?.ort, 'Deutschland')
    const region = text(place.adresse?.region).replaceAll('_', ' ')
    const tags = skills(title, '', [text(job.hauptberuf), ...(job.alleBerufe ?? [])])
    return [{
      external_id: reference,
      title: title.slice(0, 300),
      company: company.slice(0, 250),
      location: [city, region].filter(Boolean).join(' · ').slice(0, 300),
      latitude: place.breite ?? null,
      longitude: place.laenge ?? null,
      remote_type: job.homeofficemoeglich ? 'hybrid' : 'onsite',
      salary_min: null,
      salary_max: null,
      source: 'Bundesagentur für Arbeit',
      source_url: trustedHttps(
        job.externeURL,
        `https://www.arbeitsagentur.de/jobsuche/jobdetail/${encodeURIComponent(reference)}`,
      ),
      tags,
      description: tags.length > 0
        ? `Poste de Werkstudent publié pour le domaine : ${tags.join(', ')}.`
        : 'Offre de Werkstudent publiée via la Bundesagentur für Arbeit.',
      posted_at: job.datumErsteVeroeffentlichung ?? job.aenderungsdatum ?? new Date().toISOString(),
      expires_at: null,
      active: true,
    }]
  })
}

async function fetchGreenhouse(token: string, company: string): Promise<JobRow[]> {
  const response = await fetch(
    `https://boards-api.greenhouse.io/v1/boards/${encodeURIComponent(token)}/jobs?content=true`,
    { headers: { Accept: 'application/json' }, signal: AbortSignal.timeout(12_000) },
  )
  if (!response.ok) throw new Error(`Greenhouse ${company} ${response.status}`)
  const payload = await response.json() as { jobs?: GreenhouseJob[] }
  if (!Array.isArray(payload.jobs)) throw new Error(`Greenhouse ${company} malformed response`)
  const source = `Greenhouse · ${company}`
  return payload.jobs.flatMap((job) => {
    const id = job.id?.toString() ?? ''
    const title = text(job.title)
    const location = text(job.location?.name)
    if (!id || !studentRole(title) || !germanyLocation(location)) return []
    const description = stripHtml(job.content).slice(0, 8000)
    const [latitude, longitude] = coordinates(location)
    return [{
      external_id: `${token}:${id}`,
      title: title.slice(0, 300),
      company,
      location: location.slice(0, 300),
      latitude,
      longitude,
      remote_type: remoteType(location, description),
      salary_min: null,
      salary_max: null,
      source,
      source_url: trustedHttps(job.absolute_url),
      tags: skills(title, description, (job.departments ?? []).map((item) => text(item.name))),
      description: description || `Offre étudiante publiée par ${company}.`,
      posted_at: job.updated_at ?? new Date().toISOString(),
      expires_at: null,
      active: true,
    }]
  })
}

async function fetchLever(
  site: string,
  company: string,
  host: string,
): Promise<JobRow[]> {
  const response = await fetch(
    `https://${host}/v0/postings/${encodeURIComponent(site)}?mode=json`,
    { headers: { Accept: 'application/json' }, signal: AbortSignal.timeout(12_000) },
  )
  if (!response.ok) throw new Error(`Lever ${company} ${response.status}`)
  const payload = await response.json() as LeverJob[]
  if (!Array.isArray(payload)) throw new Error(`Lever ${company} malformed response`)
  const source = `Lever · ${company}`
  return payload.flatMap((job) => {
    const id = text(job.id)
    const title = text(job.text)
    const location = text(job.categories?.location, 'Allemagne')
    const commitment = text(job.categories?.commitment)
    if (!id || !studentRole(title, commitment) || !germanyLocation(location, job.country)) return []
    const description = text(job.descriptionPlain, text(job.additionalPlain)).slice(0, 8000)
    const [latitude, longitude] = coordinates(location)
    const tags = skills(title, description, [
      text(job.categories?.team),
      text(job.categories?.department),
      commitment,
    ])
    return [{
      external_id: `${site}:${id}`,
      title: title.slice(0, 300),
      company,
      location: location.slice(0, 300),
      latitude,
      longitude,
      remote_type: remoteType(location, text(job.workplaceType)),
      salary_min: null,
      salary_max: null,
      source,
      source_url: trustedHttps(job.hostedUrl),
      tags,
      description: description || `Offre étudiante publiée par ${company}.`,
      posted_at: job.createdAt ? new Date(job.createdAt).toISOString() : new Date().toISOString(),
      expires_at: null,
      active: true,
    }]
  })
}

async function fetchAdzuna(): Promise<JobRow[] | null> {
  const appId = Deno.env.get('ADZUNA_APP_ID')?.trim()
  const appKey = Deno.env.get('ADZUNA_APP_KEY')?.trim()
  if (!appId || !appKey) return null
  const endpoint = new URL('https://api.adzuna.com/v1/api/jobs/de/search/1')
  endpoint.searchParams.set('app_id', appId)
  endpoint.searchParams.set('app_key', appKey)
  endpoint.searchParams.set('results_per_page', '50')
  endpoint.searchParams.set('what', 'Werkstudent')
  endpoint.searchParams.set('where', 'Deutschland')
  endpoint.searchParams.set('content-type', 'application/json')
  const response = await fetch(endpoint, {
    headers: { Accept: 'application/json' },
    signal: AbortSignal.timeout(12_000),
  })
  if (!response.ok) throw new Error(`Adzuna ${response.status}`)
  const payload = await response.json() as { results?: AdzunaJob[] }
  if (!Array.isArray(payload.results)) throw new Error('Adzuna malformed response')
  return payload.results.flatMap((job) => {
    const id = text(job.id)
    const title = text(job.title)
    const company = text(job.company?.display_name)
    const location = text(job.location?.display_name, 'Allemagne')
    if (!id || !title || !company || !studentRole(title)) return []
    const description = stripHtml(job.description).slice(0, 8000)
    return [{
      external_id: id,
      title: title.slice(0, 300),
      company: company.slice(0, 250),
      location: location.slice(0, 300),
      latitude: job.latitude ?? null,
      longitude: job.longitude ?? null,
      remote_type: remoteType(location, description),
      salary_min: null,
      salary_max: null,
      source: 'Adzuna',
      source_url: trustedHttps(job.redirect_url),
      tags: skills(title, description, [text(job.category?.label)]),
      description: description || 'Offre de Werkstudent publiée via Adzuna.',
      posted_at: job.created ?? new Date().toISOString(),
      expires_at: null,
      active: true,
    }]
  })
}

async function fetchArbeitnow(): Promise<JobRow[]> {
  // Arbeitnow asks consumers not to abuse the free API. Three pages twice per
  // day provide a useful German student-job window while staying conservative.
  const pageResults = await Promise.all([1, 2, 3].map(async (page) => {
    const endpoint = new URL('https://www.arbeitnow.com/api/job-board-api')
    endpoint.searchParams.set('page', page.toString())
    const response = await fetch(endpoint, {
      headers: { Accept: 'application/json', 'User-Agent': 'Werkly/1.0 job discovery' },
      signal: AbortSignal.timeout(12_000),
    })
    if (!response.ok) throw new Error(`Arbeitnow page ${page} ${response.status}`)
    const payload = await response.json() as { data?: ArbeitnowJob[] }
    if (!Array.isArray(payload.data)) throw new Error(`Arbeitnow page ${page} malformed`)
    return payload.data
  }))

  const seen = new Set<string>()
  return pageResults.flat().flatMap((job) => {
    const id = text(job.slug)
    const title = text(job.title)
    const company = text(job.company_name)
    const reportedLocation = text(job.location)
    const sourceUrl = trustedHttps(job.url)
    const description = stripHtml(job.description).slice(0, 8000)
    let sourceHost = ''
    try {
      sourceHost = new URL(sourceUrl).hostname.toLowerCase()
    } catch {
      return []
    }
    const isGermanBoard = sourceHost === 'arbeitnow.com' || sourceHost === 'www.arbeitnow.com'
    if (!id || seen.has(id) || !title || !company || !sourceUrl || !isGermanBoard ||
      !studentRole(title, ...(job.job_types ?? []))) return []

    const hasGermanLocation = germanyLocation(reportedLocation) ||
      /\b(?:jobs?|stellenangebote)\s+(?:in|aus)\s+(?:germany|deutschland)\b/i.test(description)
    if (!hasGermanLocation) return []
    const location = reportedLocation || (job.remote ? 'Remote · Germany' : 'Germany')

    if (!job.created_at || !Number.isFinite(job.created_at)) return []
    const postedAt = new Date(job.created_at * 1000).toISOString()
    if (!recentEnough(postedAt)) return []
    seen.add(id)
    const [latitude, longitude] = coordinates(location)
    const tags = skills(title, description, [
      ...(job.tags ?? []),
      ...(job.job_types ?? []),
    ])
    return [{
      external_id: id.slice(0, 250),
      title: title.slice(0, 300),
      company: company.slice(0, 250),
      location: location.slice(0, 300),
      latitude,
      longitude,
      remote_type: job.remote ? 'remote' : remoteType(location, description),
      salary_min: null,
      salary_max: null,
      source: 'Arbeitnow',
      source_url: sourceUrl,
      tags,
      description: description || `Student position published by ${company}.`,
      posted_at: postedAt,
      expires_at: null,
      active: true,
    }]
  })
}

async function fetchSmartRecruiters(): Promise<JobRow[]> {
  const postings = new Map<string, SmartRecruitersPosting>()

  // List calls are intentionally sequenced per employer. SmartRecruiters caps
  // public Posting API concurrency, and this keeps the integration polite.
  for (const employer of smartRecruitersCompanies) {
    const responses = await Promise.all(['Werkstudent', 'student'].map(async (query) => {
      const content: SmartRecruitersPosting[] = []
      let offset = 0
      let complete = false
      for (let page = 0; page < 5; page++) {
        const endpoint = new URL(
          `https://api.smartrecruiters.com/v1/companies/${encodeURIComponent(employer.identifier)}/postings`,
        )
        endpoint.searchParams.set('limit', '100')
        endpoint.searchParams.set('offset', offset.toString())
        endpoint.searchParams.set('country', 'de')
        endpoint.searchParams.set('q', query)
        endpoint.searchParams.set('destination', 'PUBLIC')
        const response = await fetch(endpoint, {
          headers: { Accept: 'application/json' },
          signal: AbortSignal.timeout(12_000),
        })
        if (!response.ok) {
          throw new Error(`SmartRecruiters ${employer.company} list ${response.status}`)
        }
        const payload = await response.json() as {
          content?: SmartRecruitersPosting[]
          totalFound?: number
        }
        if (!Array.isArray(payload.content)) {
          throw new Error(`SmartRecruiters ${employer.company} malformed response`)
        }
        content.push(...payload.content)
        offset += payload.content.length
        const total = finiteNumber(payload.totalFound)
        if (payload.content.length === 0 || payload.content.length < 100 ||
          (total !== null && offset >= total)) {
          complete = true
          break
        }
      }
      if (!complete) {
        throw new Error(`SmartRecruiters ${employer.company} pagination limit reached`)
      }
      return content
    }))

    for (const response of responses) {
      for (const posting of response) {
        const id = text(posting.id)
        const title = text(posting.name)
        const country = text(posting.location?.country).toLowerCase()
        if (!id || country !== 'de' || !recentEnough(posting.releasedDate) ||
          !studentRole(title, posting.department?.label, posting.typeOfEmployment?.label)) continue
        postings.set(`${employer.identifier}:${id}`, posting)
      }
    }
  }

  const entries = [...postings.entries()]
  const rows: JobRow[] = []
  // At most six concurrent detail calls, below the provider's documented cap.
  for (let offset = 0; offset < entries.length; offset += 6) {
    const batch = entries.slice(offset, offset + 6)
    const details = await Promise.all(batch.map(async ([key, posting]) => {
      const identifier = text(posting.company?.identifier, key.split(':')[0])
      const id = text(posting.id)
      const response = await fetch(
        `https://api.smartrecruiters.com/v1/companies/${encodeURIComponent(identifier)}/postings/${encodeURIComponent(id)}`,
        { headers: { Accept: 'application/json' }, signal: AbortSignal.timeout(12_000) },
      )
      if (!response.ok) throw new Error(`SmartRecruiters detail ${id} ${response.status}`)
      return await response.json() as SmartRecruitersPostingDetail
    }))

    for (let index = 0; index < details.length; index++) {
      const detail = details[index]
      const [entryKey, listing] = batch[index]
      const identifier = text(
        detail.company?.identifier,
        text(listing.company?.identifier, entryKey.split(':')[0]),
      )
      if (detail.active === false) continue
      const id = text(detail.id, text(listing.id))
      const title = text(detail.name, text(listing.name))
      const company = text(detail.company?.name, text(listing.company?.name))
      const country = text(detail.location?.country, text(listing.location?.country)).toLowerCase()
      const location = text(
        detail.location?.fullLocation,
        text(listing.location?.fullLocation,
          [
            text(detail.location?.city, text(listing.location?.city)),
            text(detail.location?.region, text(listing.location?.region)),
            'Germany',
          ]
          .filter(Boolean).join(', '),
        ),
      )
      const sourceUrl = trustedHttps(detail.postingUrl, trustedHttps(detail.applyUrl))
      if (!id || !title || !company || !location || !sourceUrl ||
        country !== 'de') continue

      const sections = Object.values(detail.jobAd?.sections ?? {})
      const description = sections.map((section) => [
        stripHtml(section.title),
        stripHtml(section.text),
      ].filter(Boolean).join('\n')).filter(Boolean).join('\n\n').slice(0, 8000)
      const fallbackCoordinates = coordinates(location)
      const latitude = finiteNumber(detail.location?.latitude) ??
        finiteNumber(listing.location?.latitude) ?? fallbackCoordinates[0]
      const longitude = finiteNumber(detail.location?.longitude) ??
        finiteNumber(listing.location?.longitude) ?? fallbackCoordinates[1]
      const remote = detail.location?.remote ?? listing.location?.remote ?? false
      const hybrid = detail.location?.hybrid ?? listing.location?.hybrid ?? false
      const postedAt = detail.releasedDate ?? listing.releasedDate
      if (!postedAt || !recentEnough(postedAt)) continue
      rows.push({
        external_id: `${identifier}:${id}`.slice(0, 250),
        title: title.slice(0, 300),
        company: company.slice(0, 250),
        location: location.slice(0, 300),
        latitude,
        longitude,
        remote_type: remote && !hybrid ? 'remote' : hybrid ? 'hybrid' : 'onsite',
        salary_min: null,
        salary_max: null,
        source: 'SmartRecruiters',
        source_url: sourceUrl,
        tags: skills(title, description, [
          text(detail.industry?.label, text(listing.industry?.label)),
          text(detail.department?.label, text(listing.department?.label)),
          text(detail.function?.label, text(listing.function?.label)),
          text(detail.typeOfEmployment?.label, text(listing.typeOfEmployment?.label)),
        ]),
        description: description || `Student position published by ${company}.`,
        posted_at: postedAt,
        expires_at: null,
        active: true,
      })
    }
  }
  return rows
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders })
  }
  if (!isPublishableRequest(request)) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders })
  }

  const secretKeys = envJson('SUPABASE_SECRET_KEYS')
  const adminKey = secretKeys.default ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!adminKey) {
    return Response.json({ error: 'Server configuration missing' }, { status: 503, headers: corsHeaders })
  }
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, adminKey)

  const { data: state, error: readStateError } = await admin
    .from('job_sync_state')
    .select('last_synced_at,item_count,details')
    .eq('source', 'free-multi-source')
    .maybeSingle()
  if (readStateError) {
    console.error('Job sync state read failed', readStateError)
    return Response.json({ error: 'Job sync state unavailable' }, {
      status: 503,
      headers: corsHeaders,
    })
  }
  const lastSynced = state?.last_synced_at ? new Date(state.last_synced_at) : null
  if (lastSynced && Date.now() - lastSynced.getTime() < 20 * 60 * 1000) {
    return Response.json(
      { imported: 0, active: state.item_count, cached: true, sources: state.details },
      { headers: corsHeaders },
    )
  }

  const syncToken = crypto.randomUUID()
  const { data: claimed, error: claimError } = await admin.rpc('claim_free_job_sync', {
    p_token: syncToken,
  })
  if (claimError) {
    console.error('Job sync lease failed', claimError)
    return Response.json({ error: 'Job sync lease unavailable' }, {
      status: 503,
      headers: corsHeaders,
    })
  }
  if (claimed !== true) {
    return Response.json({
      imported: 0,
      active: state?.item_count ?? 0,
      cached: true,
      sync_in_progress: true,
      sources: state?.details ?? {},
    }, { headers: corsHeaders })
  }

  const tasks = [
    { source: 'Bundesagentur für Arbeit', run: fetchBundesagentur },
    ...greenhouseBoards.map((board) => ({
      source: `Greenhouse · ${board.company}`,
      run: () => fetchGreenhouse(board.token, board.company),
    })),
    ...leverSites.map((site) => ({
      source: `Lever · ${site.company}`,
      run: () => fetchLever(site.site, site.company, site.host),
    })),
    { source: 'Adzuna', run: fetchAdzuna },
    { source: 'Arbeitnow', run: fetchArbeitnow },
    { source: 'SmartRecruiters', run: fetchSmartRecruiters },
  ]
  const settled = await Promise.allSettled(tasks.map((task) => task.run()))
  const rows: JobRow[] = []
  const details: Record<string, ProviderMetrics> = {}
  const runStarted = new Date().toISOString()
  const candidates: Array<{ source: string; fetched: number; rows: JobRow[] }> = []
  let reachableProviders = 0

  for (let index = 0; index < settled.length; index++) {
    const result = settled[index]
    const source = tasks[index].source
    if (result.status === 'rejected') {
      console.error(`${source} sync failed`, result.reason)
      details[source] = {
        status: 'unavailable',
        fetched: 0,
        eligible: 0,
        deduplicated: 0,
        imported: 0,
        error: result.reason instanceof Error ? result.reason.message : 'Unknown provider error',
      }
      continue
    }
    if (result.value === null) {
      details[source] = {
        status: 'not_configured',
        fetched: 0,
        eligible: 0,
        deduplicated: 0,
        imported: 0,
      }
      continue
    }
    reachableProviders++
    const freshRows = result.value.filter((row) => recentEnough(row.posted_at))
    candidates.push({ source, fetched: result.value.length, rows: freshRows })
  }

  // Prefer direct employer feeds, then the federal source, then aggregators.
  // Identical jobs inside one provider remain untouched because two separate
  // vacancies can legitimately share a title, company and city.
  const persistedFingerprintOwners = new Map<string, string>()
  const orderedCandidates = candidates
    .sort((left, right) => sourcePriority(left.source) - sourcePriority(right.source))

  for (const provider of orderedCandidates) {
    const { source, fetched } = provider
    let deduplicated = 0
    const providerRows = provider.rows.filter((row) => {
      const owner = persistedFingerprintOwners.get(jobFingerprint(row))
      if (owner && owner !== source) {
        deduplicated++
        return false
      }
      return true
    })
    let upsertError = ''
    for (let rowIndex = 0; rowIndex < providerRows.length; rowIndex += 100) {
      const batch = providerRows.slice(rowIndex, rowIndex + 100).map((row) => ({
        ...row,
        last_seen_at: runStarted,
      }))
      const { error } = await admin.from('jobs').upsert(batch, {
        onConflict: 'source,external_id',
      })
      if (error) {
        upsertError = error.message
        console.error(`${source} upsert failed`, error)
        break
      }
    }
    if (upsertError) {
      details[source] = {
        status: 'failed',
        fetched,
        eligible: provider.rows.length + deduplicated,
        deduplicated,
        imported: 0,
        error: upsertError,
      }
      continue
    }

    // Claim fingerprints only after this provider was actually persisted. If
    // its write fails, a lower-priority source remains available as fallback.
    for (const row of providerRows) {
      const fingerprint = jobFingerprint(row)
      if (!persistedFingerprintOwners.has(fingerprint)) {
        persistedFingerprintOwners.set(fingerprint, source)
      }
    }

    const { error: deactivateError } = await admin
      .from('jobs')
      .update({ active: false })
      .eq('source', source)
      .eq('active', true)
      .lt('last_seen_at', runStarted)
    if (deactivateError) {
      console.error(`${source} stale cleanup failed`, deactivateError)
    }
    details[source] = {
      status: deactivateError ? 'failed' : 'ok',
      fetched,
      eligible: provider.rows.length + deduplicated,
      deduplicated,
      imported: providerRows.length,
      ...(deactivateError ? { error: deactivateError.message } : {}),
    }
    rows.push(...providerRows)
  }

  if (reachableProviders === 0) {
    await admin
      .from('job_sync_state')
      .update({ sync_started_at: null, sync_token: null })
      .eq('source', 'free-multi-source')
      .eq('sync_token', syncToken)
    return Response.json(
      { error: 'All public job sources are temporarily unavailable', sources: details },
      { status: 502, headers: corsHeaders },
    )
  }

  await admin.from('jobs').update({ active: false }).like('external_id', 'demo-%')
  const { count: activeCount, error: countError } = await admin
    .from('jobs')
    .select('id', { count: 'exact', head: true })
    .eq('active', true)
  if (countError) console.error('Active job count failed', countError)
  const currentActiveCount = activeCount ?? rows.length
  const { data: updatedState, error: stateError } = await admin
    .from('job_sync_state')
    .update({
      last_synced_at: new Date().toISOString(),
      item_count: currentActiveCount,
      details,
      sync_started_at: null,
      sync_token: null,
    })
    .eq('source', 'free-multi-source')
    .eq('sync_token', syncToken)
    .select('source')
    .maybeSingle()
  if (stateError || !updatedState) {
    console.error('Job sync state update failed', stateError)
    return Response.json({
      error: 'The jobs were imported but the sync state could not be finalized',
      imported: rows.length,
      active: currentActiveCount,
      sources: details,
    }, { status: 409, headers: corsHeaders })
  }

  return Response.json({
    imported: rows.length,
    active: currentActiveCount,
    cached: false,
    sources: details,
  }, {
    headers: corsHeaders,
  })
})
