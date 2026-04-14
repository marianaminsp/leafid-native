# Leaf ID Zero-Complacency Audit v1.0

Date: 2026-04-10  
Owner: CTO Office  
Status: Active baseline

## Objective

Establish the technical truth of the current product and define a premium-grade path to TestFlight with strong architecture, security, performance, and delivery hygiene.

## Current State (Observed)

- Platform is currently `Next.js + Capacitor`, not Expo React Native.
- No `app.json`/`app.config.*`, no `eas.json`, and no `expo` dependency.
- iOS app exists as a Capacitor shell with web assets copied into `ios/App/App/public`.
- Supabase and AI integration are functional prototype-level, but secrets and resilience are below production standard.

## Risk Register

### P0 - Critical

1. Platform mismatch with stated deployment strategy (Expo EAS).
2. Hardcoded client credentials in `lib/supabase.ts`.
3. Incorrect env key usage in Supabase Edge Function (`Deno.env.get(...)` with raw secret string).
4. Privacy and permission copy quality risks for App Review.

### P1 - High

1. High visual overdraw and blur stacking can fail 60fps on older devices.
2. Flip interaction is not gesture-native quality.
3. Data contracts and DB schema governance are not versioned in repo.

### P2 - Medium

1. Social "re-collect" loop not yet represented in schema/API.
2. Non-native UI signals (runtime font injection, web icon patterns) reduce premium quality perception.

## Strategic Recommendation

- Long-term premium direction: migrate to Expo React Native architecture.
- Immediate quality/security hardening: treat current codebase as a transitional prototype and remove release blockers.
- Execute in phased program with strict acceptance criteria (see roadmap and P0 board).

## Audit Changelog

- v1.0 (2026-04-10): Initial comprehensive audit baseline.
