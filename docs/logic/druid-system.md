# Druid Identity System

This document defines the canonical logic for Druid identity, progression, and energy behavior in LeafID.

## Progression Path

- `0-5` scans: `Wandering Seed` (Icon: `Seedling`)
- `6-15` scans: `Forest Sprout` (Icon: `Leaf`)
- `16-50` scans: `Oak Guardian` (Icon: `Tree`)
- `50+` scans: `Archdruid` (Icon: `Sparkles`)

## Energy System

- Base (free users): `3` scans total
- Premium users: `Unlimited` scans

## Druid Passport (UI Logic)

- If user is **not logged in**:
  - Show `Login Overlay` with `Google Sign-in`.

- If user **is logged in**:
  - Show:
    - `User Name`
    - `Rank`
    - `Energy Gauge`
  - If scans are `0`, show a `Buy me a Coffee` button.

## Implementation Note

All future features that touch Druid progression, scan gating, or passport rendering must follow this file as source-of-truth logic.
