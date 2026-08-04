# mediation-apps

Shiny apps for the mediationverse ecosystem — deployed to Posit Connect Cloud.

## Structure

Each app is a self-contained subdirectory under `apps/`:

```
apps/<app-name>/
├── app.R
├── manifest.json   # generated locally via rsconnect::writeManifest(), committed
│                    # (Connect Cloud's GitHub-connect flow reads this from the repo
│                    # directly — it does not invoke R itself)
└── README.md
```

**No `renv`.** Connect Cloud does not support renv for environment setup —
it provisions packages purely from `manifest.json`
(docs.posit.co/connect-cloud/how-to/r/dependencies.html). Its native
GitHub-connect flow clones the raw repo tree directly (not an
`rsconnect`-built bundle), so a committed `.Rprofile`/`renv/` still runs
at container startup even if `.rscignore`'d — `renv::activate()`
redirects `.libPaths()` to a project renv library Connect Cloud never
populates, and every package looks `(none)` at runtime regardless of
what's actually pinned. Generate `manifest.json` from a plain (non-renv)
R library with the app's packages installed globally:
`rsconnect::writeManifest(".")`.

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

**Native GitHub-connect publish, not a GitHub Actions workflow.** Connect
Cloud (`connect.posit.cloud`) is a different product from classic
self-hosted Posit Connect and does not expose a static API key in its UI —
`rsconnect::connectApiUser(apiKey = ...)` is for classic Connect only and
does not work here. (A GitHub Actions `deploy.yml` built around it existed
briefly in this repo's history and was removed after confirming this.)

Instead: Connect Cloud → Publish → From GitHub → select this repo → pick
the app's `ui.R` (or `app.R`) as the primary file → auto-republish on push
is on by default. Each app needs `manifest.json` committed (see Structure
above) since Connect Cloud reads it straight from the repo tree.

If a future app genuinely needs CI-driven deploy instead of the native
flow, the correct auth is `rsconnect::connectCloudClientCredentials()`
(OAuth `client_credentials`, a Connect Cloud service-account
`clientId`/`clientSecret`) — not `connectApiUser()`.

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
