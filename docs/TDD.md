# Technical Design Doc (TDD)

This TDD consolidates implementation-level rules that must be respected across LeafID code changes.

## Druid Identity System Requirements

The Druid subsystem MUST follow the canonical specification in:

- [`docs/logic/druid-system.md`](docs/logic/druid-system.md)

### Required Logic

#### Progression Path

- `0-5` scans: `Wandering Seed` (Icon: `Seedling`)
- `6-15` scans: `Forest Sprout` (Icon: `Leaf`)
- `16-50` scans: `Oak Guardian` (Icon: `Tree`)
- `50+` scans: `Archdruid` (Icon: `Sparkles`)

#### Energy System

- Free users: `3` scans total
- Premium users: `Unlimited` scans

#### Druid Passport UI

- Not logged in:
  - Show `Login Overlay` with `Google Sign-in`.
- Logged in:
  - Show `User Name`, `Rank`, `Energy Gauge`.
  - If scans are `0`, show `Buy me a Coffee` button.

## Engineering Rule

Any feature or refactor that impacts profile rank, scan quota, authentication gating, or passport presentation must be validated against this TDD and `docs/logic/druid-system.md` before merge.
