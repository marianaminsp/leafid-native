# ADR-0001: Platform Direction for Premium iOS Experience

Date: 2026-04-10  
Status: Proposed  
Decision owners: CTO, Product, Design

## Context

The current codebase is a web stack (`Next.js + Capacitor`) while product objectives target premium, native-feeling iOS behavior and scalable social evolution.

## Decision

Adopt Expo React Native as the long-term product architecture, while hardening current implementation to maintain delivery continuity.

## Consequences

### Positive

- Better path to native gesture quality and performance tuning.
- Cleaner mobile module ecosystem for camera/maps/haptics.
- Stronger long-term maintainability for mobile product growth.

### Negative

- Migration cost and temporary dual-track complexity.
- Requires careful version pinning due to local machine constraints.

## Alternatives Considered

1. Stay on Capacitor permanently.
   - Faster short-term, weaker long-term premium/native ceiling.
2. Full rewrite immediately with no stabilization.
   - High risk and loss of iterative momentum.

## Next Actions

1. Complete P0 hardening in current codebase.
2. Open migration epic with milestone-based scope.
3. Revisit this ADR as `Accepted` after kickoff approval.

