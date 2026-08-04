# mediation-apps

Shiny apps for the [mediationverse](https://github.com/Data-Wise/mediationverse)
ecosystem (`medfit`, `probmed`, `RMediation`, `medrobust`, `medsim`).

Deployed to [Posit Connect Cloud](https://docs.posit.co/connect-cloud/).

## Live apps

**[data-wise.github.io/mediation-apps](https://data-wise.github.io/mediation-apps/)**
— branded launch cards for both apps, each linking to a container page
(formula, worked example, citation) with an explicit Launch button — no
auto-redirect.

[![Launch MEDCI](https://img.shields.io/badge/%E2%96%B6-Launch%20MEDCI-2e6f63)](https://data-wise.github.io/mediation-apps/medci/)
[![Launch Monte Carlo](https://img.shields.io/badge/%E2%96%B6-Launch%20Monte%20Carlo-2e6f63)](https://data-wise.github.io/mediation-apps/medmc/)

Fallback / reference: [connect.posit.cloud/data-wise](https://connect.posit.cloud/data-wise)
lists both apps directly on Connect Cloud's own account page (this is what
[Gate 0](SPEC-shiny-apps-landing-page-2026-08-04.md) confirmed already
solves the core "long URL" problem for free — the GitHub Pages page above
is the nicer branded version for papers/teaching).

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
- [BRAINSTORM: container pages](BRAINSTORM-container-pages-2026-08-04.md) / [SPEC: container pages](SPEC-container-pages-2026-08-04.md)
