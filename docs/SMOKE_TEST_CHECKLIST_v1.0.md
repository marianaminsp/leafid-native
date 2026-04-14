# Smoke Test Checklist v1.0

Date: 2026-04-10  
Owner: QA/Engineering

## Core Flow

- [ ] App launches without crash.
- [ ] Scan screen loads and primary CTA is responsive.
- [ ] Select photo from gallery works.
- [ ] AI identification returns a result or clear error state.
- [ ] Save action stores scan row and image URL.
- [ ] Herbarium updates with latest scan.

## Permissions and Privacy

- [ ] Camera permission prompt text is clear.
- [ ] Photo library permission prompt text is clear.
- [ ] Denied permission states are handled without app crash.

## Performance and UX

- [ ] No visible jank on scan-to-result transition.
- [ ] 3D card interaction feels responsive.
- [ ] Loading overlays appear and dismiss correctly.

## Data and Error Handling

- [ ] Network failure shows actionable feedback.
- [ ] Retry path works after temporary failure.
- [ ] No uncaught errors in console for core flow.

## Release Candidate Gate

- [ ] Runbook steps completed (`docs/TESTING_AND_RELEASE_RUNBOOK_v1.0.md`).
- [ ] Latest migrations applied on target Supabase project.
- [ ] Changelog and execution board updated for current build.
