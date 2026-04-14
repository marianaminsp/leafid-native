# Testing and Release Runbook v1.0

Date: 2026-04-10  
Owner: Engineering

## Goal

Create a deterministic path from local code to iOS device test and TestFlight-ready archive.

## Local Commands

1. Build web artifacts:

```bash
npm run build:web
```

2. Sync Capacitor iOS project (with UTF-8 guard for CocoaPods):

```bash
npm run cap:sync:ios
```

3. One-shot prepare:

```bash
npm run ios:prepare
```

4. Open Xcode project:

```bash
npm run ios:open
```

## Xcode Release Flow

1. Select `Any iOS Device (arm64)`.
2. Product -> Archive.
3. Open Organizer -> Distribute App.
4. Upload to App Store Connect.
5. Add build to TestFlight internal group first.

## Environment Requirements

- `.env.local` set with:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- Supabase secret set:
  - `GROQ_API_KEY`

## Pre-Upload Gate

- Permission strings reviewed in `Info.plist`.
- Build generated from latest commit.
- Smoke checklist passed (see companion document).

## Notes

- Current architecture is transitional (`Next.js + Capacitor`).
- Keep release process deterministic and documented while UI work progresses.
