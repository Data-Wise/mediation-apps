# mediation-apps

Shiny apps for the mediationverse ecosystem — deployed to Posit Connect Cloud.

## Structure

Each app is a self-contained subdirectory under `apps/`:

```
apps/<app-name>/
├── app.R
├── renv.lock       # always — per-app dependency pin
├── manifest.json   # generated via rsconnect::writeManifest() in CI, never hand-edited
└── README.md
```

## Escalation trigger

An app promotes from a plain `app.R` to its own golem-structured package
once it needs its own test suite, versioned exports, or shared logic beyond
a single file. The golem package `Imports` its target mediationverse
package — it is never embedded inside that package's `inst/`.

When an app escalates to a golem package:

- CI-only deploy tooling (`rsconnect`) goes in `Config/Needs/deploy:
  rsconnect` in `DESCRIPTION` — never in `Imports` or `Suggests`, since app
  users never need it.
- The existing mediationverse `Imports`/`Suggests` convention (see
  mediationverse project memory
  `project_imports_suggests_selective_loading.md`) applies normally once
  the app is a real package.

## Deploy

- CI is path-filtered — only the app subdirectory that changed redeploys.
- Deploy credential (`CONNECT_API_KEY`) is a per-repo GitHub Actions
  secret, not shared across repos.
- CI regenerates `manifest.json` via `rsconnect::writeManifest()` before
  every deploy — it is Connect's environment blueprint and must never be
  hand-edited or committed stale.

## Security

- No hardcoded credentials in app code. Runtime secrets (DB connection
  strings, API keys) come from `Sys.getenv()` only.
- For static encrypted config files, use the `secret` R package's
  RSA-vault pattern rather than committing plaintext.

## Testing

- `e2e` tier via `shinytest2` (snapshot + interaction testing).
- `dogfood` — click through the deployed app from a link in
  mediationverse's README/`ecosystem.qmd`.

## Workflow

Multi-branch (craft-style): `main ← dev ← feature/*` (revised 2026-08-03
from the originally-planned single-integration pattern — see SPEC
addendum). `main` is PR-only with branch protection (0 required
reviewers, no force-push, no deletions). `dev` is the integration branch —
commits/pushes allowed directly, existing-file edits allowed, new files
should go through a `feature/*` branch once the repo has real app code.
`dev` is intentionally **not** GitHub-protected, matching the rest of the
mediation ecosystem's craft-style repos.

## Design history

Full BRAINSTORM → GRILL → REVIEW → SPEC chain lives in the
[mediationverse repo](https://github.com/Data-Wise/mediationverse) — see
`SPEC-shiny-apps-location-2026-08-03.md` there for the complete decision
record.
