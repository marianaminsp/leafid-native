# LeafID — Branding: recovery web page + Supabase emails

Design tokens match [`LeafID-native/Theme/Theme.swift`](../LeafID-native/Theme/Theme.swift) (e.g. primary `#93BC10`, surface `#0B0F08`).

## 1. GitHub Pages bridge (`index.html`)

- **Edit:** [`index.html`](../index.html) at the repo root (mirror: [`web/recovery-bridge.html`](../web/recovery-bridge.html)).
- **Publish:** commit + push `main`; GitHub **Settings → Pages** serves that file.
- **Customize:** change CSS variables in `:root`, copy, fonts, or swap the leaf glyph (`.leaf::before` uses an inline SVG mask). Google Fonts load from `fonts.googleapis.com` (same families as the app: Plus Jakarta Sans, Manrope).

No build step — static HTML only.

## 2. Supabase auth emails (password reset, confirm signup, etc.)

**Where:** [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Authentication** → **Email templates** (wording may be “Templates” / “Emails” depending on UI version).

You can override:

- **Subject** per template (e.g. recovery).
- **Body** as HTML using **Go template** variables (see [Auth email templates](https://supabase.com/docs/guides/auth/auth-email-templates)).

Common variables:

| Variable | Use |
|----------|-----|
| `{{ .ConfirmationURL }}` | Full magic link (keep this as the main button `href`) |
| `{{ .Email }}` | Recipient |
| `{{ .Token }}` | OTP / code if you show “enter code” fallback |
| `{{ .SiteURL }}` | Site URL from project settings |

**Important for email clients**

- Prefer **inline** `style="..."` on tables/cells and links; many clients strip `<style>` blocks.
- Use **absolute `https` URLs** for images (hosted on your site or CDN).
- Test in Gmail + Apple Mail; avoid complex flex/grid.

**Example** (recovery) — adapt copy; keep `{{ .ConfirmationURL }}` intact:

```html
<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#0B0F08;padding:32px 16px;font-family:Georgia,serif;">
  <tr>
    <td align="center">
      <table width="100%" style="max-width:480px;background-color:#1C2116;border-radius:16px;border:1px solid #45493F;padding:28px 24px;">
        <tr><td style="color:#93BC10;font-size:11px;letter-spacing:0.2em;text-transform:uppercase;font-weight:bold;">LeafID</td></tr>
        <tr><td style="color:#F2F5E7;font-size:22px;font-weight:bold;padding-top:12px;">Restablecer contraseña</td></tr>
        <tr><td style="color:#A9ADA0;font-size:15px;line-height:1.5;padding-top:12px;">Toca el botón para continuar. Si no pediste este correo, ignóralo.</td></tr>
        <tr><td align="center" style="padding-top:24px;">
          <a href="{{ .ConfirmationURL }}" style="background-color:#93BC10;color:#121212;text-decoration:none;font-weight:bold;padding:14px 28px;border-radius:14px;display:inline-block;">Continuar en LeafID</a>
        </td></tr>
      </table>
    </td>
  </tr>
</table>
```

## 3. Optional: custom SMTP + “from” name

**Authentication → SMTP settings** (or Project settings): send from your domain (e.g. `hola@tudominio.com`) so the inbox shows **LeafID** instead of a generic Supabase sender. Requires DNS (SPF/DKIM) per your provider’s docs.

## 4. Redirect URL reminder

`{{ .ConfirmationURL }}` must eventually hit your allow-listed URLs (GitHub Pages bridge + `com.marianaminafro.leafid://reset-password`). That is configured in **Authentication → URL configuration**, not inside the HTML template.
