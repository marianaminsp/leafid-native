import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type ProviderName = "plant.id" | "plantnet" | "gemini-vision" | "none"

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
    throw new ProviderError(rawText.trim() || "Plant.id returned non-JSON response", "non_json", true, response.status)
  }

  if (!response.ok) {
    const message =
      pickString(data?.message, data?.error) ||
      rawText.trim() ||
      "Plant.id request failed"
    const classified = classifyStatus(response.status)
    throw new ProviderError(message, classified.code, classified.retriable, response.status)
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
    throw new ProviderError(rawText.trim() || "Pl@ntNet returned non-JSON response", "non_json_backup", true, response.status)
  }

  if (!response.ok) {
    const message =
      pickString(data?.message, data?.error, data?.detail) ||
      rawText.trim() ||
      "Pl@ntNet request failed"
    const classified = classifyStatus(response.status)
    throw new ProviderError(message, `${classified.code}_backup`, classified.retriable, response.status)
  }

  return normalizePlantNet(data)
}

const identifyWithGeminiVision = async (base64Data: string, apiKey: string) => {
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
    throw new ProviderError(rawText.trim() || "Gemini Vision returned non-JSON response", "non_json_gemini", true, response.status)
  }

  if (!response.ok) {
    const message = pickString(data?.error && toRecord(data.error).message, data?.message, rawText) || "Gemini Vision request failed"
    const classified = classifyStatus(response.status)
    throw new ProviderError(message, `${classified.code}_gemini`, classified.retriable, response.status)
  }

  const candidates = Array.isArray(data.candidates) ? data.candidates : []
  const first = toRecord(candidates[0])
  const content = toRecord(first.content)
  const parts = Array.isArray(content.parts) ? content.parts : []
  const text = pickString(toRecord(parts[0]).text)
  if (!text) throw new ProviderError("Gemini Vision returned empty text payload", "empty_payload_gemini", true)

  const jsonText = normalizeJSONObjectString(text)
  let payload: Record<string, unknown>
  try {
    payload = JSON.parse(jsonText) as Record<string, unknown>
  } catch {
    throw new ProviderError("Gemini Vision produced invalid JSON object", "invalid_json_gemini", true)
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
    origin_country: pickString(payload.origin_country) || "Origin estimated by Gemini Vision",
    curiosity: pickString(payload.curiosity) || `Identified by Gemini Vision backup with ${(confidence * 100).toFixed(1)}% confidence.`,
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
    const plantIdApiKey = Deno.env.get('PLANT_ID_API_KEY')
    const plantNetApiKey = Deno.env.get('PLANTNET_API_KEY')
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')

    if (!image) throw new Error('No image provided')
    if (!plantIdApiKey) throw new ProviderError("Missing PLANT_ID_API_KEY", "missing_key", false)

    const base64Data = image.includes(',') ? image.split(',')[1] : image
    const providerChain: string[] = []

    try {
      const primary = await identifyWithPlantId(base64Data, plantIdApiKey)
      providerChain.push("plant.id")
      return new Response(
        JSON.stringify({
          ...primary,
          fallback: false,
          diagnostic_error: null,
          diagnostic_code: null,
          provider: "plant.id",
          provider_fallback_used: false,
          provider_chain: providerChain,
        } satisfies NormalizedIdentifyResult),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } catch (plantIdError) {
      providerChain.push("plant.id")
      const primaryMessage = plantIdError instanceof Error ? plantIdError.message : "Plant.id failed"
      const primaryCode = plantIdError instanceof ProviderError ? plantIdError.code : "plantid_error"
      console.error("identify-plant primary provider failed:", primaryCode, primaryMessage)

      if (plantNetApiKey) {
        try {
          const backup = await identifyWithPlantNet(base64Data, plantNetApiKey)
          providerChain.push("plantnet")
          return new Response(
            JSON.stringify({
              ...backup,
              fallback: false,
              diagnostic_error: null,
              diagnostic_code: null,
              provider: "plantnet",
              provider_fallback_used: true,
              provider_chain: providerChain,
            } satisfies NormalizedIdentifyResult),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        } catch (backupError) {
          providerChain.push("plantnet")
          const backupMessage = backupError instanceof Error ? backupError.message : "Pl@ntNet failed"
          const backupCode = backupError instanceof ProviderError ? backupError.code : "plantnet_error"
          console.error("identify-plant backup provider failed:", backupCode, backupMessage)
          if (geminiApiKey) {
            try {
              const third = await identifyWithGeminiVision(base64Data, geminiApiKey)
              providerChain.push("gemini-vision")
              return new Response(
                JSON.stringify({
                  ...third,
                  fallback: false,
                  diagnostic_error: null,
                  diagnostic_code: null,
                  provider: "gemini-vision",
                  provider_fallback_used: true,
                  provider_chain: providerChain,
                } satisfies NormalizedIdentifyResult),
                { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
              )
            } catch (geminiError) {
              providerChain.push("gemini-vision")
              const geminiMessage = geminiError instanceof Error ? geminiError.message : "Gemini Vision failed"
              const geminiCode = geminiError instanceof ProviderError ? geminiError.code : "gemini_error"
              const combined = `Plant.id [${primaryCode}]: ${primaryMessage}; Pl@ntNet [${backupCode}]: ${backupMessage}; GeminiVision [${geminiCode}]: ${geminiMessage}`
              return new Response(
                JSON.stringify(fallbackResponse(combined, "all_providers_failed", providerChain)),
                { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
              )
            }
          }
          const combined = `Plant.id [${primaryCode}]: ${primaryMessage}; Pl@ntNet [${backupCode}]: ${backupMessage}; GeminiVision unavailable (Missing GEMINI_API_KEY)`
          return new Response(
            JSON.stringify(fallbackResponse(combined, "third_fallback_unavailable", providerChain)),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
      }

      const noBackupDiagnostic = `Plant.id [${primaryCode}]: ${primaryMessage}; backup provider unavailable (Missing PLANTNET_API_KEY)`
      return new Response(
        JSON.stringify(fallbackResponse(noBackupDiagnostic, "backup_unavailable", providerChain)),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

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