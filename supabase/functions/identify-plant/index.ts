import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type ProviderName = "plant.id" | "plantnet" | "openrouter-gemini" | "gemini-direct" | "none"

type NormalizedIdentifyResult = {
  native_name: string
  common_name: string
  scientific_name: string
  family: string
  origin_country: string
  curiosity: string
  confidence: number
  fallback: boolean
  diagnostic_error: string | null
  diagnostic_code: string | null
  provider: ProviderName
  provider_fallback_used: boolean
  provider_chain: string[]
  phylum: string
  sun_exposure: string
  watering: string
}

class ProviderError extends Error {
  code: string
  retriable: boolean
  status?: number

  constructor(message: string, code: string, retriable = false, status?: number) {
    super(message)
    this.name = "ProviderError"
    this.code = code
    this.retriable = retriable
    this.status = status
  }
}

const fallbackResponse = (diagnosticError?: string, diagnosticCode?: string, providerChain: string[] = []): NormalizedIdentifyResult => ({
  native_name: "Unknown specimen",
  common_name: "Unknown specimen",
  scientific_name: "Species under review",
  family: "Unclassified",
  origin_country: "Origin under review",
  curiosity: "This specimen needs a clearer image for a confident field identification.",
  confidence: 0.2,
  fallback: true,
  diagnostic_error: diagnosticError ?? null,
  diagnostic_code: diagnosticCode ?? null,
  provider: "none",
  provider_fallback_used: providerChain.length > 0,
  provider_chain: providerChain,
  phylum: "",
  sun_exposure: "",
  watering: "",
})

const toRecord = (v: unknown): Record<string, unknown> => {
  if (typeof v === "object" && v !== null && !Array.isArray(v)) return v as Record<string, unknown>
  return {}
}

const pickString = (...values: unknown[]): string => {
  for (const v of values) {
    if (typeof v === "string") {
      const t = v.trim()
      if (t) return t
    }
  }
  return ""
}

const clamp01 = (value: number): number => Math.min(1, Math.max(0, value))

const classifyStatus = (status: number): { code: string; retriable: boolean } => {
  if (status === 401 || status === 403) return { code: "auth", retriable: false }
  if (status === 429) return { code: "rate_limit", retriable: true }
  if (status >= 500) return { code: "upstream_5xx", retriable: true }
  return { code: `http_${status}`, retriable: false }
}

const decodeBase64Image = (raw: string): Uint8Array => {
  const clean = raw.includes(",") ? raw.split(",")[1] : raw
  const normalized = clean.replace(/-/g, "+").replace(/_/g, "/")
  const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4)
  const binary = atob(padded)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i)
  return bytes
}

const normalizeJSONObjectString = (text: string): string => {
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
  if (start < 0 || end < 0 || end <= start) {
    throw new ProviderError("Gemini Vision returned non-JSON content", "non_json_gemini", true)
  }
  return withoutFence.slice(start, end + 1)
}

const pickDetailString = (v: unknown): string => {
  if (v === undefined || v === null) return ""
  if (typeof v === "string") return v.trim()
  if (typeof v === "object" && v !== null && "value" in v && typeof (v as { value: unknown }).value === "string") {
    return String((v as { value: string }).value).trim()
  }
  return String(v).trim()
}

const normalizePlantId = (payload: Record<string, unknown>): Omit<NormalizedIdentifyResult, "fallback" | "diagnostic_error" | "diagnostic_code" | "provider" | "provider_fallback_used" | "provider_chain"> => {
  const result = toRecord(payload.result)
  const classification = toRecord(result.classification)
  const suggestions = Array.isArray(classification.suggestions) ? classification.suggestions : []
  const best = toRecord(suggestions[0])
  if (!suggestions.length || !Object.keys(best).length) {
    throw new ProviderError("No species suggestion returned by Plant.id", "no_species_suggestion", false)
  }

  const details = toRecord(best.details)
  const taxonomy = toRecord(details.taxonomy)
  const commonNames = Array.isArray(details.common_names) ? details.common_names : []
  const firstCommonName = pickString(commonNames[0])
  const wikiDescription = pickString(toRecord(details.wiki_description).value, toRecord(details.description).value)
  const probability = typeof best.probability === "number" ? clamp01(best.probability) : 0.65

  const scientificName = pickString(best.name) || "Unknown species"
  const commonName = firstCommonName || scientificName
  const family = pickString(taxonomy.family) || "Unknown family"
  const originCountry = "Origin data not provided by Plant.id"
  const curiosity =
    wikiDescription
      ? `${wikiDescription.split(".")[0].trim()}.`
      : `Identified by Plant.id with ${(probability * 100).toFixed(1)}% confidence.`

  const phylum = pickString(taxonomy.phylum)

  let sunExposure = pickDetailString(details.sunlight)
  if (!sunExposure) sunExposure = pickDetailString(details.sun_exposure)
  if (!sunExposure) sunExposure = pickDetailString(details.light)

  let watering = pickDetailString(details.watering)
  if (!watering) watering = pickDetailString(details.watering_needs)
  if (Array.isArray(details.plant_details)) {
    for (const rowRaw of details.plant_details) {
      const row = toRecord(rowRaw)
      const t = pickString(row.title).toLowerCase()
      const val = pickString(row.value)
      if (!val) continue
      if (!sunExposure && (t.includes("sun") || t.includes("light"))) sunExposure = val
      if (!watering && t.includes("water")) watering = val
    }
  }

  return {
    native_name: commonName,
    common_name: commonName,
    scientific_name: scientificName,
    family,
    origin_country: originCountry,
    curiosity,
    confidence: probability,
    phylum,
    sun_exposure: sunExposure,
    watering,
  }
}

const normalizePlantNet = (payload: Record<string, unknown>): Omit<NormalizedIdentifyResult, "fallback" | "diagnostic_error" | "diagnostic_code" | "provider" | "provider_fallback_used" | "provider_chain"> => {
  const results = Array.isArray(payload.results) ? payload.results : []
  const best = toRecord(results[0])
  if (!results.length || !Object.keys(best).length) {
    throw new ProviderError("No species suggestion returned by Pl@ntNet", "no_species_suggestion_backup", false)
  }

  const species = toRecord(best.species)
  const familyRecord = toRecord(species.family)
  const genusRecord = toRecord(species.genus)
  const phylumRecord = toRecord(species.phylum)
  const commonNames = Array.isArray(species.commonNames) ? species.commonNames : []

  const scientificName = pickString(
    species.scientificNameWithoutAuthor,
    species.scientificName,
    genusRecord.scientificNameWithoutAuthor
  ) || "Unknown species"
  const commonName = pickString(commonNames[0]) || scientificName
  const family = pickString(familyRecord.scientificNameWithoutAuthor, familyRecord.scientificName) || "Unknown family"
  const phylum = pickString(phylumRecord.scientificNameWithoutAuthor, phylumRecord.scientificName)
  const score = typeof best.score === "number" ? clamp01(best.score) : 0.55

  return {
    native_name: commonName,
    common_name: commonName,
    scientific_name: scientificName,
    family,
    origin_country: "Origin data not provided by Pl@ntNet",
    curiosity: `Identified by Pl@ntNet backup with ${(score * 100).toFixed(1)}% confidence.`,
    confidence: score,
    phylum,
    sun_exposure: "",
    watering: "",
  }
}

const identifyWithPlantId = async (base64Data: string, apiKey: string) => {
  const response = await fetch(
    "https://api.plant.id/v3/identification?details=common_names,taxonomy,wiki_description,url,description",
    {
      method: "POST",
      headers: {
        "Api-Key": apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        images: [base64Data],
        similar_images: true,
        classification_level: "species",
      }),
    }
  )

  const rawText = await response.text()
  let data: Record<string, unknown>
  try {
    data = JSON.parse(rawText) as Record<string, unknown>
  } catch {
    throw new ProviderError(rawText.trim() || "Plant.id returned non-JSON response", "non_json_plantid", true, response.status)
  }

  if (!response.ok) {
    const message =
      pickString(data?.message, data?.error) ||
      rawText.trim() ||
      "Plant.id request failed"
    const classified = classifyStatus(response.status)
    throw new ProviderError(message, `${classified.code}_plantid`, classified.retriable, response.status)
  }

  return normalizePlantId(data)
}

const identifyWithPlantNet = async (base64Data: string, apiKey: string) => {
  const bytes = decodeBase64Image(base64Data)
  const formData = new FormData()
  formData.append("images", new Blob([bytes], { type: "image/jpeg" }), "capture.jpg")
  formData.append("organs", "leaf")

  const endpoint = `https://my-api.plantnet.org/v2/identify/all?include-related-images=false&api-key=${encodeURIComponent(apiKey)}`
  const response = await fetch(endpoint, {
    method: "POST",
    body: formData,
  })

  const rawText = await response.text()
  let data: Record<string, unknown>
  try {
    data = JSON.parse(rawText) as Record<string, unknown>
  } catch {
    throw new ProviderError(rawText.trim() || "Pl@ntNet returned non-JSON response", "non_json_plantnet", true, response.status)
  }

  if (!response.ok) {
    const message =
      pickString(data?.message, data?.error, data?.detail) ||
      rawText.trim() ||
      "Pl@ntNet request failed"
    const classified = classifyStatus(response.status)
    throw new ProviderError(message, `${classified.code}_plantnet`, classified.retriable, response.status)
  }

  return normalizePlantNet(data)
}

const identifyWithOpenRouterVision = async (base64Data: string, apiKey: string) => {
  const endpoint = "https://openrouter.ai/api/v1/chat/completions"
  const prompt = [
    "Identify this plant from the image and return ONLY valid JSON.",
    "Required keys: common_name, scientific_name, family, origin_country, curiosity, confidence, phylum, sun_exposure, watering.",
    "Rules:",
    "- confidence must be a number between 0 and 1",
    "- If unsure, provide best estimate but never return markdown or explanations",
  ].join("\n")
  const body = {
    model: "google/gemini-2.0-flash-001",
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: prompt },
          { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Data}` } },
        ],
      },
    ],
    temperature: 0.1,
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  })
  const rawText = await response.text()
  let data: Record<string, unknown>
  try {
    data = JSON.parse(rawText) as Record<string, unknown>
  } catch {
    throw new ProviderError(rawText.trim() || "OpenRouter/Gemini returned non-JSON response", "non_json_openrouter", true, response.status)
  }

  if (!response.ok) {
    const message = pickString(data?.error && toRecord(data.error).message, data?.message, rawText) || "OpenRouter/Gemini request failed"
    const classified = classifyStatus(response.status)
    throw new ProviderError(message, `${classified.code}_openrouter`, classified.retriable, response.status)
  }

  const choices = Array.isArray(data.choices) ? data.choices : []
  const first = toRecord(choices[0])
  const message = toRecord(first.message)
  const text = pickString(message.content)
  if (!text) throw new ProviderError("OpenRouter/Gemini returned empty text payload", "empty_payload_openrouter", true)

  const jsonText = normalizeJSONObjectString(text)
  let payload: Record<string, unknown>
  try {
    payload = JSON.parse(jsonText) as Record<string, unknown>
  } catch {
    throw new ProviderError("OpenRouter/Gemini produced invalid JSON object", "invalid_json_openrouter", true)
  }

  const confidenceRaw = payload.confidence
  const confidence = typeof confidenceRaw === "number"
    ? clamp01(confidenceRaw)
    : clamp01(Number.parseFloat(String(confidenceRaw ?? "0.45")))

  const scientificName = pickString(payload.scientific_name) || "Unknown species"
  const commonName = pickString(payload.common_name) || scientificName
  const family = pickString(payload.family) || "Unknown family"

  return {
    native_name: commonName,
    common_name: commonName,
    scientific_name: scientificName,
    family,
    origin_country: pickString(payload.origin_country) || "Origin estimated by OpenRouter/Gemini",
    curiosity: pickString(payload.curiosity) || `Identified by OpenRouter/Gemini backup with ${(confidence * 100).toFixed(1)}% confidence.`,
    confidence,
    phylum: pickString(payload.phylum),
    sun_exposure: pickString(payload.sun_exposure),
    watering: pickString(payload.watering),
  }
}

const identifyWithGeminiDirect = async (base64Data: string, apiKey: string) => {
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${encodeURIComponent(apiKey)}`
  const prompt = [
    "Identify this plant from the image and return ONLY valid JSON.",
    "Required keys: common_name, scientific_name, family, origin_country, curiosity, confidence, phylum, sun_exposure, watering.",
    "Rules:",
    "- confidence must be a number between 0 and 1",
    "- If unsure, provide best estimate but never return markdown or explanations",
  ].join("\n")
  const body = {
    contents: [
      {
        role: "user",
        parts: [
          { text: prompt },
          {
            inline_data: {
              mime_type: "image/jpeg",
              data: base64Data,
            },
          },
        ],
      },
    ],
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  })
  const rawText = await response.text()
  let data: Record<string, unknown>
  try {
    data = JSON.parse(rawText) as Record<string, unknown>
  } catch {
    throw new ProviderError(rawText.trim() || "Gemini direct returned non-JSON response", "non_json_gemini_direct", true, response.status)
  }

  if (!response.ok) {
    const message = pickString(data?.error && toRecord(data.error).message, data?.message, rawText) || "Gemini direct request failed"
    const classified = classifyStatus(response.status)
    throw new ProviderError(message, `${classified.code}_gemini_direct`, classified.retriable, response.status)
  }

  const candidates = Array.isArray(data.candidates) ? data.candidates : []
  const first = toRecord(candidates[0])
  const content = toRecord(first.content)
  const parts = Array.isArray(content.parts) ? content.parts : []
  const text = pickString(toRecord(parts[0]).text)
  if (!text) throw new ProviderError("Gemini direct returned empty text payload", "empty_payload_gemini_direct", true)

  const jsonText = normalizeJSONObjectString(text)
  let payload: Record<string, unknown>
  try {
    payload = JSON.parse(jsonText) as Record<string, unknown>
  } catch {
    throw new ProviderError("Gemini direct produced invalid JSON object", "invalid_json_gemini_direct", true)
  }

  const confidenceRaw = payload.confidence
  const confidence = typeof confidenceRaw === "number"
    ? clamp01(confidenceRaw)
    : clamp01(Number.parseFloat(String(confidenceRaw ?? "0.45")))

  const scientificName = pickString(payload.scientific_name) || "Unknown species"
  const commonName = pickString(payload.common_name) || scientificName
  const family = pickString(payload.family) || "Unknown family"

  return {
    native_name: commonName,
    common_name: commonName,
    scientific_name: scientificName,
    family,
    origin_country: pickString(payload.origin_country) || "Origin estimated by Gemini direct",
    curiosity: pickString(payload.curiosity) || `Identified by Gemini direct fallback with ${(confidence * 100).toFixed(1)}% confidence.`,
    confidence,
    phylum: pickString(payload.phylum),
    sun_exposure: pickString(payload.sun_exposure),
    watering: pickString(payload.watering),
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { image } = await req.json()
    const plantNetApiKey = Deno.env.get('PLANTNET_API_KEY')
    const plantIdApiKey = Deno.env.get('PLANT_ID_API_KEY')
    const openRouterApiKey = Deno.env.get('OPENROUTER_API_KEY')
    const geminiDirectApiKey = Deno.env.get('GEMINI_API_KEY')

    if (!image) throw new Error('No image provided')
    if (!plantNetApiKey && !plantIdApiKey && !openRouterApiKey) {
      throw new ProviderError("Missing provider keys: PLANTNET_API_KEY, PLANT_ID_API_KEY, OPENROUTER_API_KEY", "missing_all_provider_keys", false)
    }

    const base64Data = image.includes(',') ? image.split(',')[1] : image
    const providerChain: string[] = []
    let lastTechnicalError = "No provider attempted"
    let lastTechnicalCode = "no_attempt"

    const providers: Array<{
      name: ProviderName
      apiKey?: string
      missingKeyCode: string
      run: (base64Data: string, key: string) => Promise<Omit<NormalizedIdentifyResult, "fallback" | "diagnostic_error" | "diagnostic_code" | "provider" | "provider_fallback_used" | "provider_chain">>
      logLabel: string
    }> = [
      {
        name: "plantnet",
        apiKey: plantNetApiKey ?? undefined,
        missingKeyCode: "missing_plantnet_key",
        run: identifyWithPlantNet,
        logLabel: "Pl@ntNet (principal)",
      },
      {
        name: "plant.id",
        apiKey: plantIdApiKey ?? undefined,
        missingKeyCode: "missing_plantid_key",
        run: identifyWithPlantId,
        logLabel: "Plant.id (fallback 1)",
      },
      {
        name: "openrouter-gemini",
        apiKey: openRouterApiKey ?? undefined,
        missingKeyCode: "missing_openrouter_key",
        run: identifyWithOpenRouterVision,
        logLabel: "OpenRouter/Gemini (fallback 2)",
      },
      {
        name: "gemini-direct",
        apiKey: geminiDirectApiKey ?? undefined,
        missingKeyCode: "missing_gemini_direct_key",
        run: identifyWithGeminiDirect,
        logLabel: "Gemini Direct (fallback 3)",
      },
    ]

    for (const provider of providers) {
      providerChain.push(provider.name)
      if (!provider.apiKey) {
        lastTechnicalCode = provider.missingKeyCode
        lastTechnicalError = `${provider.logLabel} unavailable: missing API key`
        console.log(`[identify-plant] skipping ${provider.logLabel}: missing key`)
        continue
      }

      console.log(`[identify-plant] trying ${provider.logLabel}`)
      try {
        const normalized = await provider.run(base64Data, provider.apiKey)
        console.log(`[identify-plant] provider succeeded: ${provider.logLabel}`)
        return new Response(
          JSON.stringify({
            ...normalized,
            fallback: false,
            diagnostic_error: null,
            diagnostic_code: null,
            provider: provider.name,
            provider_fallback_used: provider.name !== "plantnet",
            provider_chain: providerChain,
          } satisfies NormalizedIdentifyResult),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      } catch (providerError) {
        const technicalMessage = providerError instanceof Error ? providerError.message : `${provider.logLabel} failed`
        const technicalCode = providerError instanceof ProviderError ? providerError.code : `${provider.name}_error`
        lastTechnicalCode = technicalCode
        lastTechnicalError = `${provider.logLabel}: ${technicalMessage}`
        console.error(`[identify-plant] ${provider.logLabel} failed:`, technicalCode, technicalMessage)
      }
    }

    return new Response(
      JSON.stringify(
        fallbackResponse(
          `All providers failed. Last error [${lastTechnicalCode}]: ${lastTechnicalError}`,
          "all_providers_failed",
          providerChain
        )
      ),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown identify-plant error"
    const code = error instanceof ProviderError ? error.code : "edge_unhandled_error"
    console.error("identify-plant fallback:", code, message)

    // Keep the mobile flow alive even when external AI provider fails.
    return new Response(JSON.stringify(fallbackResponse(message, code)), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})