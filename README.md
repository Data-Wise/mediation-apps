# mediation-apps

Shiny apps for the [mediationverse](https://github.com/Data-Wise/mediationverse)
ecosystem (`medfit`, `probmed`, `RMediation`, `medrobust`, `medsim`).

Deployed to [Posit Connect Cloud](https://docs.posit.co/connect-cloud/).

## Structure

Each app lives in its own subdirectory under `apps/`, fully self-contained
(own `renv.lock`, own `manifest.json` generated in CI). See
[CLAUDE.md](CLAUDE.md) for the full convention and the escalation path from
a plain `app.R` to a golem package.

```
apps/
└── <app-name>/
    ├── app.R
    ├── renv.lock
    ├── manifest.json    # generated via rsconnect::writeManifest() in CI, not hand-edited
    └── README.md
```

## Design standards

[DESIGN-STANDARDS.md](DESIGN-STANDARDS.md) — layout, CSS tokens,
reactive/debounce rules, validation and testing conventions extracted from
medci and medmc. Start here for any new app in this repo.

## Design history

- [BRAINSTORM](https://github.com/Data-Wise/mediationverse/blob/dev/BRAINSTORM-shiny-apps-location-2026-08-03.md)
- [GRILL](https://github.com/Data-Wise/mediationverse/blob/dev/GRILL-shiny-apps-location-2026-08-03.md)
- [REVIEW](https://github.com/Data-Wise/mediationverse/blob/dev/REVIEW-shiny-apps-location-2026-08-03.md)
- [SPEC](https://github.com/Data-Wise/mediationverse/blob/dev/SPEC-shiny-apps-location-2026-08-03.md)
- [BRAINSTORM: landing page](BRAINSTORM-shiny-apps-landing-page-2026-08-04.md) / [SPEC: landing page](SPEC-shiny-apps-landing-page-2026-08-04.md)
