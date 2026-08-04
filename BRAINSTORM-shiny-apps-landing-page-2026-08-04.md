# BRAINSTORM: A "front door" for the mediation-apps Shiny apps

Folded into [SPEC-shiny-apps-landing-page-2026-08-04.md](SPEC-shiny-apps-landing-page-2026-08-04.md) — see that file for the concrete build plan.

## Context

medci and medmc are each deployed independently to Posit Connect Cloud,
each with its own long, cloud-issued URL (`connect.posit.cloud/<user>/...`
style). The repo's own `README.md` doesn't even link to either live URL
today — there's no single place a user (or the maintainer) can go to find
"where are the apps," let alone a short, memorable address. This is an
ADHD-friendly-design problem as much as a technical one: remembering an
opaque long URL is exactly the kind of low-value working-memory tax the
apps' own UI redesign (3-zone cards, debounced live feedback, this
session's matrix-swatch/alpha-preset work) has been trying to strip out of
the *apps themselves*. The same lens applies one level up, to how people
*find* the apps in the first place.

Constraint carried over from CLAUDE.md: Connect Cloud's GitHub-connect flow
clones the raw repo tree and has no custom build step — whatever "front
door" gets built has to either live outside Connect Cloud entirely (e.g.
GitHub Pages) or be itself a third Connect Cloud app.

## Before building anything: check the platform first

**Not yet checked this session, and should gate everything below:** Posit
Connect Cloud accounts typically expose a dashboard/account page listing
every app under that account (something like
`connect.posit.cloud/<account>`). If that page is reachable and shareable
as-is, it may already solve "one URL to find both apps" for zero new work
— making the options below optional polish rather than a requirement.
Verify this first before investing in #4.

## Quick Wins (< 30 min)

1. **Add a "Live apps" section to `README.md` with the actual URLs.**
   Sounds trivial, but right now this doesn't exist — the repo documents
   *how the apps were built* but not *where to find them running*. Lowest
   possible effort, immediate value.
2. **Badge-ify the links** (shields.io-style "▶ Launch medci" /
   "▶ Launch medmc" buttons in the README) instead of bare URLs — makes the
   two options visually scannable instead of requiring the reader to parse
   prose to find a link.
3. **Cross-link the two apps' "About" panels to each other** (medci's About
   accordion links to medmc's URL and vice versa) — so a user who found one
   app via a bookmark can reach the other without going back through GitHub
   at all.
4. **QR code** for whichever URL ends up being the final "front door" —
   trivial to generate, worth having on hand for any offline/paper/slide
   context (posters, teaching handouts) given this is a research/teaching
   ecosystem.

## Medium Effort (1-2 hrs)

5. **GitHub Pages landing page (Recommended — see below).** A single
   static `docs/index.html` (or a minimal Quarto page), served via GitHub
   Pages from the `docs/` folder on `main` (the specific mechanism matters —
   see caveats below). Gives a short, memorable, permanent URL —
   `data-wise.github.io/mediation-apps/` — as the one address to remember,
   with two large ADHD-friendly launch cards (icon, one-line description,
   big button) linking out to each app's actual Connect Cloud URL. The
   visual language can reuse the same card CSS tokens already established
   (and confirmed identical, grepped from both files) in medci/medmc's own
   `ui.R`: `border-left: 4px solid #2e6f63` / `color: #2e6f63` accent,
   `border-radius: 12px`, and the exact same `box-shadow: 0 1px 2px
   rgba(32,42,39,0.06), 0 6px 20px rgba(32,42,39,0.05)` value in both files
   — so the front door can visually match the apps it leads to, not just
   approximately resemble them.

   **Caveats, not yet resolved:**
   - *Pages source mechanism*: the cost/URL-pattern claims below assume the
     `docs/` folder on `main` (not an Actions-based deploy, not a
     `gh-pages` branch) — this needs an explicit toggle in repo Settings →
     Pages, it doesn't activate just by adding the folder.
   - *Repo visibility*: if `mediation-apps` is a private repo, GitHub Pages
     requires GitHub Free-for-organizations or higher — need to confirm the
     plan before assuming this is free.
   - *Connect Cloud interaction*: CLAUDE.md's own Deploy section says
     Connect Cloud publish requires explicitly picking each app's
     `ui.R`/`app.R` as the primary file per app (not an autodetection crawl
     of the whole tree) — which suggests a `docs/` folder or
     `.github/workflows/pages.yml` sitting alongside `apps/` shouldn't
     interfere with medci/medmc's own publish config. This should be
     smoke-tested (re-publish one app after adding the Pages folder) rather
     than assumed.
6. **A redirect-only short path per app** (e.g. a GitHub Pages
   `apps/medci/index.html` that's just a meta-refresh to the real Connect
   Cloud URL) so a URL like `data-wise.github.io/mediation-apps/medci/`
   works as a memorable per-app shortcut even without visiting the landing
   page first. Pairs naturally with #5 — the landing page is the hub, these
   are direct deep-links for people who already know which app they want.
   Note the trailing slash / `index.html` requirement: GitHub Pages doesn't
   serve extensionless paths beyond directory-index resolution, so the
   exact URL shape needs to be tested, not assumed.
7. **A minimal third "hub" Shiny app deployed to Connect Cloud itself**
   (just launch cards, no computation) instead of GitHub Pages — keeps
   everything inside the Connect Cloud ecosystem the team already knows how
   to deploy/update, at the cost of a third Connect Cloud URL to
   remember (undercutting the goal somewhat) and needing its own
   `manifest.json`/deploy cycle for what is otherwise static content.

## Long-term (future sessions)

8. **Custom domain, either on GitHub Pages or on Connect Cloud directly.**
   Two sub-options with very different confidence levels:
   - *On GitHub Pages* (e.g. `apps.mediationverse.org` pointed at the Pages
     site rather than at Connect Cloud): well-documented, free, standard
     GitHub feature — the materially easier version of this.
   - *On Connect Cloud directly*: **unconfirmed this session** — whether
     Posit Connect Cloud's free/shared tier supports custom domains at all,
     or whether that requires the paid tier or self-hosted Posit Connect,
     needs to be verified against current Connect Cloud docs (flagging
     rather than asserting either way).
9. **Consolidate medci + medmc into a single multi-tab Shiny app** ("one
   mediation toolkit," each method as a tab) — genuinely solves "only one
   URL to remember," but is a real architectural change, not a landing-page
   fix, and crosses the golem-package escalation trigger already documented
   in `CLAUDE.md`. Bigger scope than this brainstorm's ask.

## Considered and deprioritized

- Trying to change or shorten the Connect-Cloud-issued URLs themselves —
  they're cloud-assigned, not something this repo controls. The fix has to
  be a memorable *front door* pointing at them, not altering them directly.
- A URL-shortener service (bit.ly-style). This is a durability-vs-setup-time
  tradeoff, not a strict loss: a shortener needs zero implementation work
  and gives a working link in under a minute, versus GitHub Pages' ~1-2 hrs
  of setup. It was deprioritized because it adds an external dependency and
  link-rot risk for something GitHub Pages solves permanently and for free
  — but it's a reasonable stopgap to use *while* #5/#6 are being built, not
  a dismissed idea.

## Recommended Next Step

→ **First, check whether Connect Cloud's own account dashboard already
solves this for free** (see "Before building anything," above) — that's a
five-minute check that could make everything else optional.

→ If not: **start with #5 (GitHub Pages landing page)** because it directly
solves "users shouldn't have to remember long URLs" with one short,
permanent, free address (for a public repo, served via the `docs/` folder
method — see caveats under #5); needs no new infrastructure beyond enabling
Pages on a repo that already exists; and can visually reuse the card CSS
tokens confirmed identical in this session's medci/medmc UI work, so the
front door and the apps it leads to feel like one coherent product rather
than a generic directory listing. Smoke-test the Connect Cloud interaction
caveat (re-publish one app after adding the Pages folder) before treating
this as done.
