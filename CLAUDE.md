<!-- working-agreement: confirmed 2026-08-22 -->
## Working agreement

Standing laws: `~/.claude/CLAUDE.md`, confirmed for this project on 2026-08-22.

### What this repo is

A take-home technical challenge (see [task/README.md](task/README.md)): a server-driven
dynamic form builder in Flutter. The two files the challenge itself provided (`README.md`,
`sample.ai.md`) live under `task/`, untouched, so they stay distinguishable from anything
written for the submission. `ai.md` (mine to write, never generated) and `.notes/ai-log.md`
(gitignored raw material for it) stay at repo root. The submission's own docs — `README.md`
and `ARCHITECTURE.md` — also live at repo root. All application code lives in
`dynamic_form_builder/` — a deliberate split so the challenge material and the actual
deliverable don't mix in the same tree.

### Project slots

- **Verify command:** `flutter analyze && flutter test`, run from `dynamic_form_builder/`
  (fast subset during iteration); full gate adds
  `flutter build ios --simulator --no-codesign`.
- **Default branch:** `main` — all 3 GitHub merge strategies are enabled on the repo, but it
  doesn't matter: PRs stay open for self-review, nothing merges as part of this submission.
- **Design system:** `dynamic_form_builder/lib/core/design_system/` — tokens → theme →
  components. Server-supplied style hints are resolved to the nearest token, never applied
  as raw values (see [ARCHITECTURE.md](ARCHITECTURE.md)).
- **Locales:** `fa`, `en`. Source locale `en`, default runtime locale `fa`, RTL-aware.
- **Run target:** iOS Simulator. Captures/screenshots for PRs are taken there, never on the
  paired physical iPhone.
- **Issue conventions:** none — no issues are filed for this repo (see override below).
- **Indexed:** CodeGraph — not yet; the repo has no source tree until Branch 1's scaffold
  commit lands. Initialize with `codegraph init` right after that commit.

### Architecture

**RiverPod Architecture** (user-supplied diagram): Presentation → Application →
{Domain, Data}, Data → Domain, Domain depends on nothing. Feature-first layout inside
`dynamic_form_builder/lib/shared/dynamic_form/{presentation,application,domain,data}/`.
Full rationale, the dependency-shape diagram, the `core`/`shared`/`features` boundary rule,
and the layer-skip/provider-colocation conventions live in [ARCHITECTURE.md](ARCHITECTURE.md)
— this file is a decision record, not a design doc.

Two hard constraints given directly by the user, independent of the diagram:
- No horizontal dependencies — no feature reaches into another feature's layers directly;
  no same-layer sibling reaches sideways outside the sanctioned chain.
- No bottom-to-top dependency direction — Domain depends on nothing; Data and Application
  both depend inward on Domain only; nothing in Domain or Data ever imports Application or
  Presentation.

### Overrides to the standing laws

- **§2 Branches & worktrees** → this submission uses **3 stacked branches**
  (`feat/design-system` → `feat/domain-data` → `feat/application-presentation`), each
  cut from the tip of the previous rather than from `main`, because each later branch has a
  genuine compile-time dependency on the one before it (Data needs Domain, Presentation
  needs Application/Data/Domain). CLAUDE.md §2 flags this as the explicit exception to
  "never stack a new unit on another unit's branch" — a real dependency exists, so it's
  called out here rather than done silently. Reason: the four architecture layers cannot be
  built or reviewed as independent, parallel units; they're a single dependency chain split
  for reviewability, not three unrelated features.
- **§4 PRs & follow-ups (merge)** → PRs are opened and left **open** for the user's own
  review; none are merged as part of this submission. Reason: this is a personal fork
  submitted to a third party for review, not a repo the user merges into their own main.
- **§4 PRs & follow-ups (deferred work)** → no tracked issues, no `roadmap`/`tech-debt`
  labels, no "known limitations" section in any PR. Anything cut for scope is simply not
  built and not logged. Reason: this is a temporary, single-submission repo with no ongoing
  backlog and one contributor — the tracked-issue process this law describes exists to
  prevent silent scope loss across a project's lifetime, which doesn't apply to a repo that
  ends at submission.
- **Platform scope** → iOS only, matching the verified local environment (no Android build
  attempted, and per the override above, not filed as deferred work either).
