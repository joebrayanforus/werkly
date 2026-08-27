import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type SupportedLanguage = 'de' | 'en' | 'fr'

const copies = {
  de: {
    addCv: 'Füge zuerst einen Lebenslauf zu deinem Profil hinzu.',
    consentRequired: 'Deine Zustimmung ist vor der Lebenslaufanalyse erforderlich.',
    unsupportedFormat: 'Dieses Lebenslaufformat wird nicht unterstützt.',
    quota: 'Das kostenlose Limit ist erreicht. Du kannst drei Lebensläufe innerhalb von 24 Stunden analysieren.',
    unknown: 'Unbekannt',
    extracted: 'Aus dem Lebenslauf',
    notConfigured: 'Die KI-Lebenslaufanalyse ist noch nicht konfiguriert.',
    tooLarge: 'Der Lebenslauf überschreitet die maximale Größe von 10 MB.',
    notReadable: 'Der Lebenslauf konnte nicht gelesen werden. Verwende eine PDF-Datei mit auswählbarem Text.',
    failed: 'Die Lebenslaufanalyse ist fehlgeschlagen. Versuche es in einigen Augenblicken erneut.',
    prompt: `Analysiere diesen Lebenslauf für ein berufliches Profil zur Suche nach Werkstudentenstellen in Deutschland.
Verbindliche Regeln:
- extrahiere ausschließlich Informationen, die tatsächlich im Dokument stehen;
- erfinde keine Kompetenz, Erfahrung, Zeitangabe, Sprache, Ausbildung oder Niveaustufe;
- verwende "Unbekannt", wenn ein Niveau nicht angegeben ist;
- verwende kurze, einheitliche Kompetenznamen, zum Beispiel Flutter, Python, SQL oder Deutsch;
- gib Telefonnummer und Adresse nur zurück, wenn sie wörtlich im Lebenslauf stehen, sonst einen leeren String;
- schreibe die Zusammenfassung auf Deutsch, sachlich und für das Profil wiederverwendbar;
- begründe jede erkannte Kompetenz kurz mit Inhalt aus dem Lebenslauf;
- nenne fehlende oder mehrdeutige wichtige Angaben im Feld warnings.`,
  },
  en: {
    addCv: 'Add a CV to your profile first.',
    consentRequired: 'Your consent is required before CV analysis.',
    unsupportedFormat: 'This CV format is not supported.',
    quota: 'The free limit has been reached. You can analyze three CVs in a 24-hour period.',
    unknown: 'Unknown',
    extracted: 'Extracted from CV',
    notConfigured: 'AI CV analysis has not been configured yet.',
    tooLarge: 'The CV exceeds the maximum size of 10 MB.',
    notReadable: 'The CV could not be read. Use a PDF with selectable text.',
    failed: 'CV analysis failed. Try again in a few moments.',
    prompt: `Analyze this CV to build a professional profile for working-student positions in Germany.
Mandatory rules:
- extract only information that is actually present in the document;
- do not invent skills, experience, dates, languages, education or proficiency levels;
- use "Unknown" when a level is not stated;
- use short canonical skill names such as Flutter, Python, SQL or German;
- only return a phone number or address if it is written verbatim in the CV, otherwise an empty string;
- write the summary in English, factual and reusable in the profile;
- support every detected skill with short evidence from the CV;
- list important missing or ambiguous information in warnings.`,
  },
  fr: {
    addCv: 'Ajoute d’abord un CV à ton profil.',
    consentRequired: 'Ton consentement est requis avant l’analyse du CV.',
    unsupportedFormat: 'Format de CV non pris en charge.',
    quota: 'Limite gratuite atteinte. Tu peux analyser trois CV par période de 24 heures.',
    unknown: 'Inconnu',
    extracted: 'Extrait du CV',
    notConfigured: 'L’analyse IA du CV n’est pas encore configurée.',
    tooLarge: 'Le CV dépasse la taille maximale de 10 Mo.',
    notReadable: 'Le contenu du CV n’a pas pu être lu. Essaie un PDF avec du texte sélectionnable.',
    failed: 'L’analyse du CV a échoué. Réessaie dans quelques instants.',
    prompt: `Analyse ce CV pour construire un profil professionnel destiné à des postes de Werkstudent en Allemagne.
Règles obligatoires :
- extrais uniquement les informations réellement présentes dans le document ;
- n’invente aucune compétence, expérience, date, langue, formation ou niveau ;
- indique "Inconnu" lorsqu’un niveau n’est pas écrit ;
- conserve des noms de compétences courts et canoniques, par exemple Flutter, Python, SQL ou Deutsch ;
- ne renvoie un numéro de téléphone ou une adresse que s'ils figurent textuellement dans le CV, sinon une chaîne vide ;
- le résumé doit être en français, factuel et réutilisable dans le profil ;
- les preuves doivent être courtes et provenir du CV ;
- signale dans warnings les informations importantes absentes ou ambiguës.`,
  },
} as const

function preferredLanguage(value: unknown): SupportedLanguage {
  return value === 'de' || value === 'fr' ? value : 'en'
}

const analysisSchema = {
  type: 'object',
  properties: {
    summary: {
      type: 'string',
      description: 'Professional summary in the requested language, grounded only in the CV, maximum 500 characters.',
    },
    phone: {
      type: 'string',
      description: 'Phone number exactly as written in the CV header, or an empty string if none is present.',
    },
    address: {
      type: 'string',
      description: 'Postal address exactly as written in the CV header (street, postal code, city), or an empty string if none is present.',
    },
    skills: {
      type: 'array',
      maxItems: 30,
      items: {
        type: 'object',
        properties: {
          name: { type: 'string', description: 'Canonical skill name.' },
          level: { type: 'string', description: 'Explicit level or inferred familiarity. Use the requested language word for Unknown when absent.' },
          evidence: { type: 'string', description: 'Short CV evidence supporting the skill.' },
        },
        required: ['name', 'level', 'evidence'],
        additionalProperties: false,
      },
    },
    languages: {
      type: 'array',
      maxItems: 12,
      items: {
        type: 'object',
        properties: {
          language: { type: 'string' },
          level: { type: 'string', description: 'CEFR level when written, otherwise the requested language word for Unknown.' },
          evidence: { type: 'string' },
        },
        required: ['language', 'level', 'evidence'],
        additionalProperties: false,
      },
    },
    experiences: {
      type: 'array',
      maxItems: 15,
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          organization: { type: 'string' },
          period: { type: 'string' },
          highlights: { type: 'array', maxItems: 5, items: { type: 'string' } },
        },
        required: ['title', 'organization', 'period', 'highlights'],
        additionalProperties: false,
      },
    },
    education: {
      type: 'array',
      maxItems: 8,
      items: {
        type: 'object',
        properties: {
          degree: { type: 'string' },
          institution: { type: 'string' },
          period: { type: 'string' },
        },
        required: ['degree', 'institution', 'period'],
        additionalProperties: false,
      },
    },
    suggestedDegree: { type: 'string' },
    suggestedUniversity: { type: 'string' },
    warnings: { type: 'array', maxItems: 10, items: { type: 'string' } },
  },
  required: [
    'summary',
    'phone',
    'address',
    'skills',
    'languages',
    'experiences',
    'education',
    'suggestedDegree',
    'suggestedUniversity',
    'warnings',
  ],
  additionalProperties: false,
}

function publishableKey() {
  try {
    const keys = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? '{}') as Record<string, string>
    return keys.default ?? Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  } catch {
    return Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  }
}

function mimeType(path: string) {
  const extension = path.split('.').pop()?.toLowerCase()
  if (extension === 'pdf') return 'application/pdf'
  return ''
}

function toBase64(bytes: Uint8Array) {
  let binary = ''
  const chunkSize = 0x8000
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize))
  }
  return btoa(binary)
}

function interactionText(value: unknown) {
  const result = value && typeof value === 'object' ? value as Record<string, unknown> : {}
  const direct = clean(result.output_text, 50_000)
  if (direct) return direct

  const outputText = cleanItems(result.outputs, 20)
    .flatMap((item) => {
      if (!item || typeof item !== 'object') return []
      const output = item as Record<string, unknown>
      return output.type === 'text' ? [clean(output.text, 50_000)] : []
    })
    .filter(Boolean)
    .join('\n')
    .trim()
  if (outputText) return outputText

  return cleanItems(result.steps, 20)
    .flatMap((step) => {
      if (!step || typeof step !== 'object') return []
      const entry = step as Record<string, unknown>
      if (entry.type !== 'model_output') return []
      return cleanItems(entry.content, 20).flatMap((item) => {
        if (!item || typeof item !== 'object') return []
        const content = item as Record<string, unknown>
        return content.type === 'text' ? [clean(content.text, 50_000)] : []
      })
    })
    .filter(Boolean)
    .join('\n')
    .trim()
}

function parseJsonObject(value: string) {
  const withoutFence = value
    .replace(/^\s*```(?:json)?\s*/i, '')
    .replace(/\s*```\s*$/i, '')
    .trim()
  try {
    return JSON.parse(withoutFence)
  } catch {
    const start = withoutFence.indexOf('{')
    const end = withoutFence.lastIndexOf('}')
    if (start < 0 || end <= start) throw new Error('AI_INVALID_JSON')
    return JSON.parse(withoutFence.slice(start, end + 1))
  }
}

function clean(value: unknown, maximum = 500) {
  return typeof value === 'string' ? value.trim().slice(0, maximum) : ''
}

function cleanItems(value: unknown, limit: number) {
  return Array.isArray(value) ? value.slice(0, limit) : []
}

function adminClient() {
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim()
  const url = Deno.env.get('SUPABASE_URL')?.trim()
  if (!serviceRoleKey || !url) return null
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
}

async function reserveCvQuota(userId: string) {
  const admin = adminClient()
  if (!admin) return ''
  const since = new Date(Date.now() - 24 * 60 * 60 * 1_000).toISOString()
  const { count, error } = await admin
    .from('ai_usage_events')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('feature', 'cv_analysis')
    .gte('created_at', since)
  if (error || (count ?? 0) >= 3) return ''
  const { data, error: insertError } = await admin
    .from('ai_usage_events')
    .insert({ user_id: userId, feature: 'cv_analysis' })
    .select('id')
    .single()
  return insertError || data?.id == null ? '' : String(data.id)
}

async function releaseCvQuota(eventId: string) {
  if (!eventId) return
  const admin = adminClient()
  if (!admin) return
  await admin.from('ai_usage_events').delete().eq('id', eventId)
}

function normalizeAnalysis(value: unknown, unknownLabel: string) {
  const raw = value && typeof value === 'object' ? value as Record<string, unknown> : {}
  const skills = cleanItems(raw.skills, 30).flatMap((item) => {
    if (!item || typeof item !== 'object') return []
    const entry = item as Record<string, unknown>
    const name = clean(entry.name, 80)
    if (!name) return []
    return [{ name, level: clean(entry.level, 40) || unknownLabel, evidence: clean(entry.evidence, 240) }]
  })
  const languages = cleanItems(raw.languages, 12).flatMap((item) => {
    if (!item || typeof item !== 'object') return []
    const entry = item as Record<string, unknown>
    const language = clean(entry.language, 60)
    if (!language) return []
    return [{
      language,
      level: clean(entry.level, 40) || unknownLabel,
      evidence: clean(entry.evidence, 240),
    }]
  })
  const experiences = cleanItems(raw.experiences, 15).flatMap((item) => {
    if (!item || typeof item !== 'object') return []
    const entry = item as Record<string, unknown>
    const title = clean(entry.title, 160)
    const organization = clean(entry.organization, 160)
    if (!title && !organization) return []
    return [{
      title,
      organization,
      period: clean(entry.period, 80),
      highlights: cleanItems(entry.highlights, 5)
        .map((highlight) => clean(highlight, 300))
        .filter(Boolean),
    }]
  })
  const education = cleanItems(raw.education, 8).flatMap((item) => {
    if (!item || typeof item !== 'object') return []
    const entry = item as Record<string, unknown>
    const degree = clean(entry.degree, 180)
    const institution = clean(entry.institution, 180)
    if (!degree && !institution) return []
    return [{ degree, institution, period: clean(entry.period, 80) }]
  })
  return {
    summary: clean(raw.summary, 500),
    phone: clean(raw.phone, 40),
    address: clean(raw.address, 200),
    skills,
    languages,
    experiences,
    education,
    suggestedDegree: clean(raw.suggestedDegree, 180),
    suggestedUniversity: clean(raw.suggestedUniversity, 180),
    warnings: cleanItems(raw.warnings, 10)
      .map((warning) => clean(warning, 240))
      .filter(Boolean),
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders })
  }

  const authorization = request.headers.get('Authorization') ?? ''
  const token = authorization.replace(/^Bearer\s+/i, '')
  const key = publishableKey()
  if (!token || !key) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders })
  }

  const client = createClient(Deno.env.get('SUPABASE_URL')!, key, {
    global: { headers: { Authorization: authorization } },
  })
  const { data: authData, error: authError } = await client.auth.getUser(token)
  if (authError || !authData.user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders })
  }
  let requestedLanguage: unknown
  try {
    const body: unknown = await request.json()
    if (body && typeof body === 'object' && 'language' in body) {
      requestedLanguage = (body as Record<string, unknown>).language
    }
  } catch {
    // Older clients send an empty body; account metadata remains the fallback.
  }
  const language = preferredLanguage(
    requestedLanguage ?? authData.user.user_metadata?.preferred_language,
  )
  const copy = copies[language]

  const { data: profile, error: profileError } = await client
    .from('profiles')
    .select('cv_path,cv_ai_consent_at,full_name,professional_summary,degree,university,skills,phone,address')
    .eq('id', authData.user.id)
    .maybeSingle()
  if (profileError || !profile?.cv_path) {
    return Response.json({ error: copy.addCv }, {
      status: 400,
      headers: corsHeaders,
    })
  }
  if (!profile.cv_ai_consent_at) {
    return Response.json({ error: copy.consentRequired }, {
      status: 403,
      headers: corsHeaders,
    })
  }

  const type = mimeType(profile.cv_path)
  if (!type) {
    return Response.json({ error: copy.unsupportedFormat }, {
      status: 415,
      headers: corsHeaders,
    })
  }

  // A server-side configuration problem must never consume a student's quota.
  const apiKey = Deno.env.get('GEMINI_API_KEY')?.trim()
  if (!apiKey) {
    await client.from('profiles').update({
      cv_analysis_status: 'failed',
      cv_analysis_error: copy.notConfigured,
      updated_at: new Date().toISOString(),
    }).eq('id', authData.user.id)
    return Response.json(
      { error: copy.notConfigured },
      { status: 503, headers: corsHeaders },
    )
  }

  const quotaEventId = await reserveCvQuota(authData.user.id)
  if (!quotaEventId) {
    return Response.json(
      { error: copy.quota },
      { status: 429, headers: { ...corsHeaders, 'Retry-After': '86400' } },
    )
  }

  await client.from('profiles').update({
    cv_analysis_status: 'processing',
    cv_analysis_error: '',
  }).eq('id', authData.user.id)

  try {
    const { data: document, error: downloadError } = await client.storage
      .from('cvs')
      .download(profile.cv_path)
    if (downloadError || !document) throw new Error('CV_DOWNLOAD_FAILED')
    if (document.size > 10 * 1024 * 1024) throw new Error('CV_TOO_LARGE')

    const bytes = new Uint8Array(await document.arrayBuffer())
    const prompt = `${copy.prompt}

Return ONLY one valid JSON object, without Markdown or commentary, with exactly this structure:
{
  "summary": "",
  "phone": "",
  "address": "",
  "skills": [{"name": "", "level": "", "evidence": ""}],
  "languages": [{"language": "", "level": "", "evidence": ""}],
  "experiences": [{"title": "", "organization": "", "period": "", "highlights": [""]}],
  "education": [{"degree": "", "institution": "", "period": ""}],
  "suggestedDegree": "",
  "suggestedUniversity": "",
  "warnings": [""]
}
Use empty arrays when the CV contains no item for a list.`

    const model = clean(Deno.env.get('GEMINI_MODEL'), 80) || 'gemini-3.6-flash'
    const response = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/interactions',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
        body: JSON.stringify({
          model,
          input: [
            { type: 'document', mime_type: type, data: toBase64(bytes) },
            { type: 'text', text: prompt },
          ],
        }),
        signal: AbortSignal.timeout(45_000),
      },
    )
    const result = await response.json()
    if (!response.ok) {
      console.error('Gemini CV analysis error', response.status, JSON.stringify(result).slice(0, 800))
      throw new Error('AI_REQUEST_FAILED')
    }
    const rawText = interactionText(result)
    if (!rawText) throw new Error('AI_EMPTY_RESPONSE')
    const analysis = normalizeAnalysis(parseJsonObject(rawText), copy.unknown)
    if (analysis.skills.length === 0 && analysis.experiences.length === 0 && analysis.education.length === 0) {
      throw new Error('CV_NOT_READABLE')
    }

    const existingSkills = cleanItems(profile.skills, 40).flatMap((item) => {
      if (typeof item === 'string') return [clean(item, 80)]
      if (!item || typeof item !== 'object') return []
      return [clean((item as Record<string, unknown>).name, 80)]
    }).filter(Boolean)
    const extractedSkills = [
      ...existingSkills,
      ...analysis.skills.map((item) => item.name),
      ...analysis.languages.map((item) =>
        item.level.toLowerCase() === copy.unknown.toLowerCase()
          ? item.language
          : `${item.language} ${item.level}`
      ),
    ].filter((item, index, all) =>
      item && all.findIndex((candidate) => candidate.toLowerCase() === item.toLowerCase()) === index
    ).slice(0, 40)
    const updates: Record<string, unknown> = {
      cv_analysis: analysis,
      cv_analysis_status: 'complete',
      cv_analysis_error: '',
      cv_analyzed_at: new Date().toISOString(),
      skills: extractedSkills.map((name) => ({ name, level: copy.extracted })),
      profile_completion: Math.max(75, Math.min(100, 55 + extractedSkills.length * 2)),
      updated_at: new Date().toISOString(),
    }
    if (!clean(profile.professional_summary)) updates.professional_summary = analysis.summary
    if (!clean(profile.degree)) updates.degree = analysis.suggestedDegree
    if (!clean(profile.university)) updates.university = analysis.suggestedUniversity
    if (!clean(profile.phone) && analysis.phone) updates.phone = analysis.phone
    if (!clean(profile.address) && analysis.address) updates.address = analysis.address

    const { data: updated, error: updateError } = await client
      .from('profiles')
      .update(updates)
      .eq('id', authData.user.id)
      .select()
      .single()
    if (updateError) throw new Error('PROFILE_UPDATE_FAILED')

    return Response.json({ profile: updated, analysis }, { headers: corsHeaders })
  } catch (error) {
    const code = error instanceof Error ? error.message : 'CV_ANALYSIS_FAILED'
    await releaseCvQuota(quotaEventId)
    const publicMessage = code === 'AI_NOT_CONFIGURED'
      ? copy.notConfigured
      : code === 'CV_TOO_LARGE'
      ? copy.tooLarge
      : code === 'CV_NOT_READABLE'
      ? copy.notReadable
      : copy.failed
    await client.from('profiles').update({
      cv_analysis_status: 'failed',
      cv_analysis_error: publicMessage,
      updated_at: new Date().toISOString(),
    }).eq('id', authData.user.id)
    return Response.json({ error: publicMessage }, { status: 502, headers: corsHeaders })
  }
})
