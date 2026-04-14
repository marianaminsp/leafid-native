import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const fallbackResponse = (diagnosticError?: string) => ({
  native_name: "Unknown specimen",
  common_name: "Unknown specimen",
  scientific_name: "Species under review",
  family: "Unclassified",
  origin_country: "Origin under review",
  curiosity: "This specimen needs a clearer image for a confident field identification.",
  confidence: 0.2,
  fallback: true,
  diagnostic_error: diagnosticError ?? null,
  phylum: "",
  sun_exposure: "",
  watering: "",
})

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { image } = await req.json()
    const plantIdApiKey = Deno.env.get('PLANT_ID_API_KEY')
    
    if (!image) throw new Error('No image provided')
    if (!plantIdApiKey) throw new Error('Missing PLANT_ID_API_KEY')

    const base64Data = image.includes(',') ? image.split(',')[1] : image

    const response = await fetch(
      "https://api.plant.id/v3/identification?details=common_names,taxonomy,wiki_description,url,description",
      {
        method: "POST",
        headers: {
          "Api-Key": plantIdApiKey,
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
      throw new Error(rawText.trim() || "Plant.id returned non-JSON response")
    }

    if (!response.ok) {
      const message =
        (typeof data?.message === "string" && data.message) ||
        (typeof data?.error === "string" && data.error) ||
        rawText.trim() ||
        "Plant.id request failed"
      throw new Error(message)
    }

    const suggestions = data?.result?.classification?.suggestions ?? []
    const best = suggestions[0]
    if (!best) throw new Error("No species suggestion returned by Plant.id")

    const details = best?.details ?? {}
    const taxonomy = details?.taxonomy ?? {}
    const commonNames = Array.isArray(details?.common_names) ? details.common_names : []
    const firstCommonName = commonNames[0]
    const wikiDescription = details?.wiki_description?.value ?? details?.description?.value ?? ""
    const probability = typeof best?.probability === "number" ? best.probability : 0.65

    const scientificName = String(best?.name ?? "Unknown species")
    const commonName = String(firstCommonName || scientificName)
    const family = String(taxonomy?.family ?? "Unknown family")
    const originCountry = "Origin data not provided by Plant.id"
    const curiosity =
      wikiDescription && typeof wikiDescription === "string"
        ? wikiDescription.split(".")[0].trim() + "."
        : `Identified by Plant.id with ${(probability * 100).toFixed(1)}% confidence.`

    const phylumRaw = taxonomy?.phylum
    const phylum =
      phylumRaw !== undefined && phylumRaw !== null && String(phylumRaw).trim() !== ""
        ? String(phylumRaw).trim()
        : ""

    const pickDetailString = (v: unknown): string => {
      if (v === undefined || v === null) return ""
      if (typeof v === "string") return v.trim()
      if (typeof v === "object" && v !== null && "value" in v && typeof (v as { value: unknown }).value === "string") {
        return String((v as { value: string }).value).trim()
      }
      return String(v).trim()
    }

    let sunExposure = pickDetailString(details.sunlight)
    if (!sunExposure) sunExposure = pickDetailString(details.sun_exposure)
    if (!sunExposure) sunExposure = pickDetailString(details.light)

    let watering = pickDetailString(details.watering)
    if (!watering) watering = pickDetailString(details.watering_needs)

    if (Array.isArray(details.plant_details)) {
      for (const row of details.plant_details as { title?: string; value?: string }[]) {
        const t = String(row?.title ?? "").toLowerCase()
        const val = String(row?.value ?? "").trim()
        if (!val) continue
        if (!sunExposure && (t.includes("sun") || t.includes("light"))) sunExposure = val
        if (!watering && t.includes("water")) watering = val
      }
    }

    const normalized = {
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

    return new Response(JSON.stringify(normalized), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown identify-plant error"
    console.error("identify-plant fallback:", message)

    // Keep the mobile flow alive even when external AI provider fails.
    return new Response(JSON.stringify(fallbackResponse(message)), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})