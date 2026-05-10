# Swift migration guide (LeafID)

Audience: iOS engineers rebuilding the client in SwiftUI (or UIKit) while keeping Supabase and the existing edge function.

Date: 2026-04-11

---

## 1. Critical: `public.scans` ownership column

The web app expects an ownership UUID column on **`public.scans`** that matches **`auth.users.id`** for the signed-in user.

- **Canonical name in this repo:** `user_id` (`uuid`, nullable until backfilled), added in  
  `supabase/migrations/20260410_0002_scans_ownership_baseline.sql`  
  (`add column if not exists user_id uuid`, optional FK to `auth.users`, index).

If Postgres or the Supabase client returns **`column scans.user_id does not exist`**, the **remote project has not applied that migration**. Fix in Supabase:

1. SQL Editor → run the contents of `20260410_0002_scans_ownership_baseline.sql`, **or**
2. `supabase link` + `supabase db push` from a machine with the CLI.

**Do not ship the native app** against a project that is missing this column if you rely on per-user Herbarium lists and RLS.

**Optional web override:** If a legacy database used a different **column name** for the same UUID (same semantics as `auth.uid()`), set:

`NEXT_PUBLIC_SCANS_USER_COLUMN=your_column_name`

The Next.js app reads this in `lib/scansUserColumn.ts` for inserts and Herbarium queries. **RLS policies must use the same column** (see `20260410_0001_rls_baseline.sql`).

---

## 2. Schema snapshot (app-facing)

### `public.scans` (as used by Preserve + Herbarium)

The native app also stores **optional Plant.id / identify-plant fields** on the local `Scan` model (`family`, `description_text`, `sun_exposure`, `watering`, `phylum`, `origin_country`, `tag_secondary`, `is_new_discovery`) for the botanical card UI. Postgres may omit these columns until you add a migration; the Swift model treats them as optional for Codable compatibility.

| Column (typical)   | Notes |
|--------------------|--------|
| `id`               | Primary key (uuid or bigint—whatever your DB uses). |
| `user_id`          | **Owner** = `auth.users.id`. Required for RLS + list filter. |
| `tree_id`          | Optional FK to `public.trees`; app sends `null` if tree registration failed. |
| `common_name`      | Display name. |
| `scientific_name`  | Latin / scientific name. |
| `photo_url`        | Public URL from Storage bucket `plant-photos` (or data URL fallback). |
| `confidence`       | Numeric (e.g. 0–1). |
| `location`         | String placeholder in current app (e.g. `"Sarriguren, ES"`). |
| `created_at`       | Default `now()` recommended. |

**Future (map):** nullable `latitude` / `longitude` on `scans` are planned for Arboretum pins; not required for Identify → Preserve → Herbarium.

### `public.trees`

Catalog rows keyed by scientific name; app inserts with camelCase fields where the table expects them (`scientificName`, `commonName`, etc.)—**confirm your live `trees` column names** before mirroring in Swift.

### Storage

- **Web (Next.js):** bucket **`plant-photos`** (see `lib/botanyService.ts`).
- **iOS (this repo):** bucket **`plant-images`** with objects at `{auth.uid}/{scan_id}.jpg` and public read — see `supabase/migrations/20260509_0005_plant_images_bucket.sql`.
- Upload image bytes (JPEG), then store the **public object URL** in `scans.photo_url`.

---

## 3. Identify flow (end-to-end)

1. **Capture:** Camera or photo library → image bytes / base64.
2. **AI identify:** `POST` to Supabase Edge Function **`identify-plant`** with body `{ "image": "<base64 without data URL prefix or with server stripping>" }`.  
   - Implementation: `supabase/functions/identify-plant/index.ts` (Plant.id).  
   - Client helper: `botanyService.identifyPlantWithAI` in `lib/botanyService.ts`.
3. **Normalize result:** Map API fields to `common_name`, `scientific_name`, `family`, `origin_country`, `curiosity`, `confidence`, etc. (see `normalizeAIResult` in `lib/botanyService.ts`).
4. **Preserve:**
   - Upload photo → public URL.
   - **Optional:** upsert/select `trees` by scientific name (`getOrRegisterTree`).
   - **Insert `scans`** with ownership column + names + `photo_url` + `confidence` + `location` (`saveUserCapture`).
5. **Herbarium:** `select * from scans where <ownership_column> = current_user_id order by created_at desc`.

---

## 4. Brand colors (HEX)

| Token        | HEX       | Usage |
|-------------|-----------|--------|
| Surface     | `#0B0F08` | Primary screen background (`LeafIDTheme.surface`). |
| Primary     | `#93BC10` | Homepage accent, CTAs, tab selection (`LeafIDTheme.primary`). |
| Primary container | `#8DC104` | Tonal partner / gradients (`LeafIDTheme.primaryContainer`). |
| On primary  | `#121212` | Icons and labels on solid primary (`LeafIDTheme.onPrimary`). |

**Subtitle / secondary label (Tailwind `text-slate-500`):** `#64748b` (Slate 500).

---

## 5. “Liquid glass” (Herbarium standard)

Used for the **header panel** and **list rows** in the Herbarium pattern.

**Header panel** (`HerbariumStandardHeader`):

- **Background:** `rgba(255, 255, 255, 0.1)`
- **Backdrop blur:** `24px` (`backdrop-filter` + `-webkit-backdrop-filter`)
- **Border:** `1px solid rgba(255, 255, 255, 0.15)`
- **Corner radius:** `28px` (`rounded-[28px]`)
- **Inner padding:** `24px` (`p-6`)

**Typography (header):**

- **Title:** Plus Jakarta Sans, `text-4xl`, `font-extrabold`, `tracking-tight`, first line `text-white`, accent line `color #649219`.
- **Subtitle:** `text-sm`, `font-medium`, `tracking-wide`, color slate-500 (`#64748b`).

**List row** (Herbarium cards): same liquid-glass values with `p-4` and optional stronger border on first row (`border-[#649219]/40`, `bg-white/[0.12]`).

---

## 6. Auth: password reset redirect (Capacitor / universal link)

Supabase **`resetPasswordForEmail`** must use a redirect URL your iOS app handles.

**Required value (current app):**

`com.marianaminafro.leafid://reset-password`

- Defined in `lib/auth.ts` as `PASSWORD_RESET_REDIRECT_TO`.
- Add this exact URL to **Supabase Dashboard → Authentication → URL configuration → Redirect URLs**.
- Register the same **URL scheme** in Xcode (Info → URL Types) for the LeafID target.

Apple Sign-In and other flows are documented in comments in `lib/auth.ts` and `capacitor.config.ts`.

---

## 7. Reference files (TypeScript)

| Concern | Path |
|--------|------|
| Scans ownership column helper | `lib/scansUserColumn.ts` |
| Identify + upload + save | `lib/botanyService.ts` |
| Herbarium load query | `app/page.tsx` (`loadData`) |
| Supabase client | `lib/supabase.ts` |
| Password reset redirect | `lib/auth.ts` |

---

## 8. Suggested Swift checklist

- [ ] Apply or verify `user_id` on `public.scans` and RLS matching `auth.uid()`.
- [ ] Mirror Identify → Preserve sequence; handle insert errors explicitly (no silent success).
- [ ] Reuse HEX + glass specs for visual parity with marketing/TestFlight expectations.
- [ ] Wire password reset deep link: `com.marianaminafro.leafid://reset-password`.
