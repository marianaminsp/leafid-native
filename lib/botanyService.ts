import { supabase } from './supabase'
import { getScansUserColumn } from './scansUserColumn'

type AIPlantResult = {
  common_name?: string
  commonName?: string
  native_name?: string
  nativeName?: string
  scientific_name?: string
  scientificName?: string
  family?: string
  rarity?: string
  origin_country?: string
  originCountry?: string
  curiosity?: string
  one_line_curiosity?: string
  main_properties?: string
  lore_history?: string
  confidence?: number
  error?: string
}

type TreeRecord = {
  id?: string
  commonName?: string
  scientificName?: string
  common_name?: string
  scientific_name?: string
  rarity?: string
  confidence?: number
}

const asString = (value: unknown, fallback: string): string =>
  typeof value === 'string' && value.trim().length > 0 ? value : fallback

const asNumber = (value: unknown, fallback: number): number =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback

const extractFunctionErrorMessage = async (error: unknown): Promise<string> => {
  if (!(error instanceof Error)) return 'Unknown AI error'

  const maybeContext = (error as { context?: Response }).context
  if (!maybeContext) return error.message

  try {
    const payload = await maybeContext.clone().json() as { error?: string; message?: string }
    return payload.error || payload.message || error.message
  } catch {
    try {
      const text = await maybeContext.clone().text()
      return text || error.message
    } catch {
      return error.message
    }
  }
}

const normalizeAIResult = (raw: unknown): AIPlantResult => {
  const data = (typeof raw === 'object' && raw !== null ? raw : {}) as Record<string, unknown>
  const commonName = asString(data.common_name ?? data.commonName, 'Unknown specimen')
  const scientificName = asString(data.scientific_name ?? data.scientificName, 'Unknown species')
  const originCountry = asString(data.origin_country ?? data.originCountry, 'Unknown origin')
  const family = asString(data.family, 'Unknown family')
  const curiosity = asString(data.curiosity ?? data.one_line_curiosity ?? data.lore_history, 'No curiosity available yet.')

  return {
    ...data,
    common_name: commonName,
    commonName,
    native_name: asString(data.native_name ?? data.nativeName ?? commonName, commonName),
    nativeName: asString(data.native_name ?? data.nativeName ?? commonName, commonName),
    scientific_name: scientificName,
    scientificName,
    origin_country: originCountry,
    originCountry,
    family,
    curiosity,
    one_line_curiosity: curiosity,
    lore_history: asString(data.lore_history, curiosity),
    confidence: asNumber(data.confidence, 0.85),
  }
}

const localFallbackResult = (message: string): AIPlantResult => ({
  native_name: 'Unknown specimen',
  common_name: 'Unknown specimen',
  scientific_name: 'Species under review',
  family: 'Unclassified',
  origin_country: 'Origin under review',
  curiosity: 'Botanist AI is temporarily unavailable. Please retry with stable connection.',
  one_line_curiosity: 'Botanist AI is temporarily unavailable. Please retry with stable connection.',
  lore_history: 'Botanist AI is temporarily unavailable. Please retry with stable connection.',
  confidence: 0.2,
  error: message,
})

export const botanyService = {
  async identifyPlantWithAI(base64Image: string) {
    try {
      const cleanBase64 = base64Image.includes(',') 
        ? base64Image.split(',')[1] 
        : base64Image;

      const request = supabase.functions.invoke('identify-plant', {
        body: { image: cleanBase64 },
      })
      const timeout = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('Botanist AI timed out. Please retry.')), 20000)
      )
      const { data, error } = await Promise.race([request, timeout]);

      if (error) throw error;
      return normalizeAIResult(data);
    } catch (error: unknown) {
      const message = await extractFunctionErrorMessage(error)
      console.error("❌ [AI Service] Fallo:", message);
      return localFallbackResult(message)
    }
  },

  async uploadPhoto(photoData: string) {
    try {
      console.log("🚀 [Storage] Convirtiendo y subiendo...");
      let blob: Blob;

      if (photoData.startsWith('data:')) {
        const base64Data = photoData.split(',')[1];
        const byteCharacters = atob(base64Data);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        blob = new Blob([new Uint8Array(byteNumbers)], { type: 'image/jpeg' });
      } else {
        const response = await fetch(photoData);
        blob = await response.blob();
      }

      const fileName = `img_${Date.now()}.jpg`;

      const { error } = await supabase.storage
        .from('plant-photos')
        .upload(fileName, blob, { contentType: 'image/jpeg' });

      if (error) throw error;

      const { data: publicUrlData } = supabase.storage
        .from('plant-photos')
        .getPublicUrl(fileName);

      console.log("✅ [Storage] Subida exitosa:", publicUrlData.publicUrl);
      return publicUrlData.publicUrl;
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Unknown storage error'
      console.error("❌ [Storage] Fallo:", message);
      return photoData;
    }
  },

  async getOrRegisterTree(aiData: AIPlantResult) {
    try {
      const scientificName = asString(aiData.scientific_name || aiData.scientificName, 'Unknown species')
      const { data: existingTree } = await supabase
        .from('trees')
        .select('*')
        .eq('scientificName', scientificName)
        .maybeSingle();

      if (existingTree) return existingTree;

      const { data: newTree, error: insertError } = await supabase
        .from('trees')
        .insert([{
          scientificName,
          commonName: asString(aiData.common_name || aiData.commonName, 'Unknown plant'),
          rarity: asString(aiData.rarity, 'Common'),
          origin_country: asString(aiData.origin_country, 'Unknown'),
          main_properties: asString(aiData.main_properties, 'Healthy'),
          lore_history: asString(aiData.lore_history, 'N/A'),
          xpValue: 50
        }])
        .select().single();

      if (insertError) throw insertError;
      return newTree;
    } catch (error: unknown) {
      console.error("❌ Error trees:", error);
      return aiData;
    }
  },

  async saveUserCapture(treeData: TreeRecord, photoUrl: string) {
    const { data: sessionWrap } = await supabase.auth.getSession()
    let userId = sessionWrap.session?.user?.id ?? null
    if (!userId) {
      const { data: authData } = await supabase.auth.getUser()
      userId = authData.user?.id ?? null
    }
    if (!userId) {
      throw new Error(
        'Sign in required to Preserve. Open the Druid tab or sign in again if your session expired.'
      )
    }

    const rawTreeId = treeData.id != null && String(treeData.id).trim() !== '' ? String(treeData.id) : null

    const ownerCol = getScansUserColumn()
    const row: Record<string, unknown> = {
      tree_id: rawTreeId,
      common_name: asString(treeData.common_name || treeData.commonName, 'Unknown plant'),
      scientific_name: asString(treeData.scientific_name || treeData.scientificName, 'Unknown species'),
      photo_url: photoUrl,
      confidence: asNumber(treeData.confidence, 0.95),
      location: 'Sarriguren, ES',
      [ownerCol]: userId,
    }

    const { data, error } = await supabase.from('scans').insert([row]).select('id').single()

    if (error) {
      console.error('❌ [DB] scans insert failed:', error.message, error)
      throw new Error(error.message || 'Could not save to Herbarium (check RLS and table columns).')
    }

    console.log('💾 [DB] scan saved:', data?.id)
    return data
  },
}
