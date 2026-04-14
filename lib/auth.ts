import { Capacitor } from '@capacitor/core'
import { supabase } from './supabase'

function randomNonce(): string {
  const a = new Uint8Array(16)
  crypto.getRandomValues(a)
  return Array.from(a, (b) => b.toString(16).padStart(2, '0')).join('')
}

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? ''
const defaultBundleId = 'com.marianaminafroa.leafid'

/**
 * iOS native: enable "Sign In with Apple" in Xcode (Signing & Capabilities).
 * Supabase Dashboard → Auth → Providers → Apple: add this App ID (bundle id) to Client IDs.
 * Optional: NEXT_PUBLIC_APPLE_REDIRECT_URI = your Apple Services ID return URL (often Supabase callback).
 */
export async function signInWithApple(): Promise<{ error: Error | null }> {
  try {
    if (Capacitor.getPlatform() === 'ios') {
      const { SignInWithApple } = await import('@capacitor-community/apple-sign-in')
      const clientId = process.env.NEXT_PUBLIC_APPLE_IOS_CLIENT_ID || defaultBundleId
      const redirectURI =
        process.env.NEXT_PUBLIC_APPLE_REDIRECT_URI ||
        `${supabaseUrl.replace(/\/$/, '')}/auth/v1/callback`
      const nonce = randomNonce()

      const result = await SignInWithApple.authorize({
        clientId,
        redirectURI,
        scopes: 'email name',
        state: 'leafid',
        nonce,
      })

      const token = result.response?.identityToken
      if (!token) throw new Error('Apple did not return an identity token')

      const { error } = await supabase.auth.signInWithIdToken({
        provider: 'apple',
        token,
        nonce,
      })
      if (error) throw error
      return { error: null }
    }

    const redirectTo =
      typeof window !== 'undefined' ? `${window.location.origin}/` : undefined
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'apple',
      options: {
        redirectTo,
        skipBrowserRedirect: false,
      },
    })
    if (error) throw error
    return { error: null }
  } catch (e) {
    const err = e instanceof Error ? e : new Error(String(e))
    return { error: err }
  }
}

export async function signInWithEmail(email: string, password: string) {
  return supabase.auth.signInWithPassword({ email: email.trim(), password })
}

export async function signUpWithEmail(email: string, password: string) {
  const emailRedirectTo =
    typeof window !== 'undefined' ? `${window.location.origin}/` : undefined
  return supabase.auth.signUp({
    email: email.trim(),
    password,
    options: { emailRedirectTo },
  })
}

export async function signOut() {
  return supabase.auth.signOut()
}

/** Must match Capacitor `appId` + URL scheme; whitelist in Supabase Auth → Redirect URLs. */
const PASSWORD_RESET_REDIRECT_TO = 'com.marianaminafro.leafid://reset-password'

export async function sendPasswordResetEmail(email: string) {
  return supabase.auth.resetPasswordForEmail(email.trim(), {
    redirectTo: PASSWORD_RESET_REDIRECT_TO,
  })
}
