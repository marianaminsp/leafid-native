import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Server-side twin of BotanyService.swift's old geminiNarrative/openRouterNarrative — moved here so
// the cultural/historical narrative (Botanical Spirit, Ethnobotany, Cultural Legacy) no longer requires
// GEMINI_API_KEY/OPENROUTER_API_KEY embedded in the shipped iOS binary. Backed by a shared,
// species-keyed cache (public.plant_narrative_cache): once any user's scan generates content for a
// species, every later scan of that species — by any user — reads the cached row for free, no model
// call. Provider chain (only used on a cache miss) is Groq first, Gemini's free-tier direct API as
// fallback — see ADR-0004 for why OpenRouter isn't in the active chain right now.

type NarrativeResult = {
  origin?: string
  botanical_spirit?: string
  ethnobotany?: string
  cultural_legacy?: string
  colors?: string[]
}

type CachedRow = {
  scientific_name_key: string
  scientific_name: string
  common_name: string | null
  family: string | null
  origin_country: string | null
  botanical_spirit: string | null
  ethnobotany: string | null
  cultural_legacy: string | null
  legacy_fact: string | null
  colors: string[] | null
  hit_count: number
}

const normalizeJSONObjectString = (text: string): string | null => {
  const trimmed = text.trim()
  const withoutFence = trimmed.startsWith("```")
    ? trimmed
      .replaceAll("```json", "")
      .replaceAll("```JSON", "")
      .replaceAll("```", "")
      .trim()
    : trimmed
  const start = withoutFence.indexOf("{")
  const end = withoutFence.lastIndexOf("}")
  if (start < 0 || end < 0 || end <= start) return null
  return withoutFence.slice(start, end + 1)
}

// Shared parser for OpenAI-compatible chat completions responses (Groq, and OpenRouter when it's
// re-enabled) — both return `choices[0].message.content` as a JSON-in-text payload.
const parseChatCompletionsResult = (rawText: string, label: string, debug: string[]): NarrativeResult | null => {
  let data: Record<string, unknown>
  try {
    data = JSON.parse(rawText) as Record<string, unknown>
  } catch {
    debug.push(`${label}: non-JSON body ${rawText.slice(0, 200)}`)
    return null
  }
  const choices = Array.isArray(data.choices) ? data.choices : []
  const first = choices[0] as Record<string, unknown> | undefined
  const message = (first?.message ?? {}) as Record<string, unknown>
  const text = typeof message.content === "string" ? message.content : ""
  if (!text) { debug.push(`${label}: empty content, raw=${JSON.stringify(data).slice(0, 300)}`); return null }

  const jsonText = normalizeJSONObjectString(text)
  if (!jsonText) { debug.push(`${label}: could not extract JSON from text=${text.slice(0, 200)}`); return null }
  try {
    return JSON.parse(jsonText) as NarrativeResult
  } catch {
    debug.push(`${label}: JSON.parse failed on ${jsonText.slice(0, 200)}`)
    return null
  }
}

const buildPrompt = (
  commonName: string,
  scientificName: string,
  family: string,
  originCountry: string,
  useFallbackPrompt: boolean
): string => {
  if (useFallbackPrompt) {
    return [
      "Return ONLY valid JSON (no markdown, no explanations, no code fences).",
      "Required keys:",
      "- origin",
      "- botanical_spirit",
      "- ethnobotany",
      "- cultural_legacy",
      "- colors",
      "Rules:",
      "- Write about a mysterious plant found in nature (generic, poetic, grounded).",
      "- Never use the words \"under review\" or \"unknown\".",
      "- origin: short location string (country or region)",
      "- botanical_spirit / ethnobotany / cultural_legacy: each <= 220 chars",
      "- colors: array with exactly 3 hex values in #RRGGBB format",
    ].join("\n")
  }
  return [
    "Return ONLY valid JSON (no markdown, no explanations, no code fences).",
    "Required keys:",
    "- origin",
    "- botanical_spirit",
    "- ethnobotany",
    "- cultural_legacy",
    "- colors",
    "Rules:",
    "- origin: short location string (country or region)",
    "- botanical_spirit / ethnobotany / cultural_legacy: each <= 220 chars",
    "- colors: array with exactly 3 hex values in #RRGGBB format",
    `Species: ${scientificName}`,
    `Common name: ${commonName}`,
    `Family: ${family}`,
    `Origin: ${originCountry}`,
  ].join("\n")
}

// Narrower prompt for "one more fact" on legacy scans saved before narrative content existed —
// twin of the old client-side geminiCulturalLegacyFact prompt, now server-side like everything else.
const buildLegacyFactPrompt = (commonName: string, scientificName: string, family: string): string => [
  `Return ONLY valid JSON (no markdown, no code fences). Single key "cultural_legacy": one engaging`,
  `sentence (<=220 chars) sharing a verifiable fact about History, Mythology, or Art associated with`,
  `this specific plant species. Prefer the species-specific angle (a documented historical use, a`,
  `named myth, or an artistic depiction). Avoid medical claims, avoid invented folklore, and do not`,
  `hedge with phrases like "is said to". If no specific cultural fact exists for the species, write`,
  `one sentence about the family's documented role in horticulture, botanical illustration, or`,
  `ornamental gardens.`,
  `Species: ${scientificName}`,
  `Common name: ${commonName}`,
  `Family: ${family}`,
].join(" ")

const narrateWithGroq = async (prompt: string, apiKey: string, debug: string[]): Promise<NarrativeResult | null> => {
  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.6,
    }),
  })
  if (response.status === 429) { debug.push("groq: 429 rate limited"); return null }
  const rawText = await response.text()
  if (!response.ok) { debug.push(`groq: HTTP ${response.status} ${rawText.slice(0, 300)}`); return null }
  return parseChatCompletionsResult(rawText, "groq", debug)
}

// Shelved: OPENROUTER_API_KEY is currently invalid (401 "User not found") and "openrouter/free" was
// never a real OpenRouter model ID — verified live against openrouter.ai/collections/free-models,
// whose actual free vision/text models use IDs like "google/gemma-4-26b-a4b-it:free". Re-enable by
// rotating the key, swapping in a real :free model ID, and calling this from the provider chain below
// (see ADR-0004). Kept here, unused, rather than deleted, so re-enabling is a small diff.
const narrateWithOpenRouter = async (prompt: string, apiKey: string, debug: string[]): Promise<NarrativeResult | null> => {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "google/gemma-4-26b-a4b-it:free",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.6,
    }),
  })
  if (response.status === 429) { debug.push("openrouter: 429 rate limited"); return null }
  const rawText = await response.text()
  if (!response.ok) { debug.push(`openrouter: HTTP ${response.status} ${rawText.slice(0, 300)}`); return null }
  return parseChatCompletionsResult(rawText, "openrouter", debug)
}

const narrateWithGeminiDirect = async (prompt: string, apiKey: string, debug: string[]): Promise<NarrativeResult | null> => {
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${encodeURIComponent(apiKey)}`
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
    }),
  })
  const rawText = await response.text()
  if (!response.ok) { debug.push(`gemini: HTTP ${response.status} ${rawText.slice(0, 300)}`); return null }

  let data: Record<string, unknown>
  try {
    data = JSON.parse(rawText) as Record<string, unknown>
  } catch {
    debug.push(`gemini: non-JSON body ${rawText.slice(0, 200)}`)
    return null
  }
  const candidates = Array.isArray(data.candidates) ? data.candidates : []
  const first = candidates[0] as Record<string, unknown> | undefined
  const content = (first?.content ?? {}) as Record<string, unknown>
  const parts = Array.isArray(content.parts) ? content.parts : []
  const text = typeof (parts[0] as Record<string, unknown> | undefined)?.text === "string"
    ? (parts[0] as Record<string, unknown>).text as string
    : ""
  if (!text) { debug.push(`gemini: empty text, raw=${JSON.stringify(data).slice(0, 300)}`); return null }

  const jsonText = normalizeJSONObjectString(text)
  if (!jsonText) { debug.push(`gemini: could not extract JSON from text=${text.slice(0, 200)}`); return null }
  try {
    return JSON.parse(jsonText) as NarrativeResult
  } catch {
    debug.push(`gemini: JSON.parse failed on ${jsonText.slice(0, 200)}`)
    return null
  }
}

const hasMissingFields = (n: NarrativeResult | null, isLegacyFact: boolean): boolean => {
  if (!n) return true
  if (isLegacyFact) return !n.cultural_legacy
  return !n.botanical_spirit || !n.ethnobotany || !n.cultural_legacy
}

// --- Shared species cache (public.plant_narrative_cache) ---

const normalizeScientificNameKey = (raw: string): string =>
  raw.trim().toLowerCase().replace(/\s+/g, " ")

const getCachedRow = async (key: string, supabaseUrl: string, serviceRoleKey: string): Promise<CachedRow | null> => {
  try {
    const response = await fetch(
      `${supabaseUrl}/rest/v1/plant_narrative_cache?scientific_name_key=eq.${encodeURIComponent(key)}&select=*&limit=1`,
      { headers: { apikey: serviceRoleKey, Authorization: `Bearer ${serviceRoleKey}` } }
    )
    if (!response.ok) return null
    const rows = await response.json() as CachedRow[]
    return rows[0] ?? null
  } catch {
    return null
  }
}

const bumpHitCount = (key: string, currentHitCount: number, supabaseUrl: string, serviceRoleKey: string): void => {
  fetch(`${supabaseUrl}/rest/v1/plant_narrative_cache?scientific_name_key=eq.${encodeURIComponent(key)}`, {
    method: "PATCH",
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify({ hit_count: currentHitCount + 1 }),
  }).catch(() => {})
}

// Upsert only the columns provided — PostgREST's merge-duplicates upsert updates just the columns
// present in the body, so a legacy-fact-only write doesn't clobber an existing general narrative row.
const upsertCache = async (
  row: Record<string, unknown>,
  supabaseUrl: string,
  serviceRoleKey: string
): Promise<void> => {
  try {
    await fetch(`${supabaseUrl}/rest/v1/plant_narrative_cache`, {
      method: "POST",
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify(row),
    })
  } catch {
    // Best-effort — a failed cache write just means the next request pays the model cost again.
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { commonName, scientificName, family, originCountry, useFallbackPrompt, mode } = await req.json()
    if (!commonName || !scientificName) {
      return new Response(JSON.stringify({} satisfies NarrativeResult), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const isLegacyFact = mode === "legacy_fact"
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const cacheKey = normalizeScientificNameKey(scientificName)
    const debug: string[] = []

    // 1. Cache read-through — species already scanned by anyone, no model call needed.
    if (supabaseUrl && serviceRoleKey) {
      const cached = await getCachedRow(cacheKey, supabaseUrl, serviceRoleKey)
      const cacheSatisfies = cached && (isLegacyFact ? Boolean(cached.legacy_fact) : Boolean(cached.botanical_spirit && cached.ethnobotany && cached.cultural_legacy))
      if (cached && cacheSatisfies) {
        bumpHitCount(cacheKey, cached.hit_count, supabaseUrl, serviceRoleKey)
        const result: NarrativeResult = isLegacyFact
          ? { cultural_legacy: cached.legacy_fact ?? undefined }
          : {
            origin: cached.origin_country ?? undefined,
            botanical_spirit: cached.botanical_spirit ?? undefined,
            ethnobotany: cached.ethnobotany ?? undefined,
            cultural_legacy: cached.cultural_legacy ?? undefined,
            colors: cached.colors ?? undefined,
          }
        return new Response(JSON.stringify({ ...result, _debug: ["cache: hit"] }), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    } else {
      debug.push("cache: SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY not set, skipping")
    }

    // 2. Cache miss — run the provider chain.
    const groqApiKey = Deno.env.get('GROQ_API_KEY')
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    const prompt = isLegacyFact
      ? buildLegacyFactPrompt(commonName, scientificName, family ?? "")
      : buildPrompt(commonName, scientificName, family ?? "", originCountry ?? "Unknown", Boolean(useFallbackPrompt))

    if (!groqApiKey) debug.push("groq: GROQ_API_KEY not set")
    if (!geminiApiKey) debug.push("gemini: GEMINI_API_KEY not set")

    const groqResult = groqApiKey ? await narrateWithGroq(prompt, groqApiKey, debug) : null
    const result = hasMissingFields(groqResult, isLegacyFact) && geminiApiKey
      ? { ...(groqResult ?? {}), ...(await narrateWithGeminiDirect(prompt, geminiApiKey, debug) ?? {}) }
      : groqResult

    // 3. Write-through — only cache fields that actually came back non-empty.
    if (supabaseUrl && serviceRoleKey && result) {
      const row: Record<string, unknown> = {
        scientific_name_key: cacheKey,
        scientific_name: scientificName,
        common_name: commonName,
        family: family ?? null,
      }
      if (isLegacyFact) {
        if (result.cultural_legacy) row.legacy_fact = result.cultural_legacy
      } else {
        if (result.origin) row.origin_country = result.origin
        if (result.botanical_spirit) row.botanical_spirit = result.botanical_spirit
        if (result.ethnobotany) row.ethnobotany = result.ethnobotany
        if (result.cultural_legacy) row.cultural_legacy = result.cultural_legacy
        if (result.colors?.length) row.colors = result.colors
      }
      if (Object.keys(row).length > 4) {
        row.source = groqResult && !hasMissingFields(groqResult, isLegacyFact) ? "groq" : "gemini"
        await upsertCache(row, supabaseUrl, serviceRoleKey)
      }
    }

    return new Response(JSON.stringify({ ...(result ?? {} satisfies NarrativeResult), _debug: debug }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error("narrate-plant error:", error instanceof Error ? error.message : error)
    // Best-effort content — never fail the request; the client already has local textual fallbacks.
    return new Response(JSON.stringify({ ...({} satisfies NarrativeResult), _debug: [String(error)] }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
