# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A centralized source of shared **Flutter/iOS** development assets (architecture rules, iOS release
workflow, App Store review checks, `docs/process` procedures) distributed to consuming Flutter apps.
It stacks a Flutter/iOS-specific layer on top of the general-purpose
[`shared-claude-code`](https://github.com/tatsushige-i/shared-claude-code) repository. All consuming repositories — and
`shared-claude-code` — must live in the same parent directory as this one (sibling placement).

**Distribution methods:**

- **Rules, skills, and `docs/process`** — distributed via symlinks into the consuming app
  (`bootstrap.sh` for initial wiring, `config-flutter-ios-sync` for incremental sync)
- **App-specific values** — never embedded in shared files. They live in each app's
  `.claude/flutter-ios-profile.md` and are referenced in shared files via `{{token}}` placeholders

## Architecture

- **rules/flutter-ios/** — Flutter/iOS rule files, symlinked into consuming apps
- **skills/** — Skill definitions (`config-flutter-ios-sync`, `release-ios-build`,
  `review-appstore-guidelines`), symlinked into consuming apps
- **docs/process/** — Development/operations procedures, symlinked into consuming apps
- **bootstrap.sh** — Single entry point; run from a target app's root to wire everything
- **flutter-ios-profile.md.template** — Per-app profile template copied by `bootstrap.sh`
- **.claude/** — Symlinks to `rules/` and `skills/` for this repo's own reference

## The `{{token}}` / profile model

Shared docs and skills are kept **pristine** (no per-app values) so that re-syncing never conflicts.
App-specific identifiers appear as `{{token}}` placeholders (e.g. `{{bundle_id}}`, `{{team_id}}`,
`{{site_domain}}`) and are resolved at read time from the consuming app's
`.claude/flutter-ios-profile.md`. The full token list is defined in
`flutter-ios-profile.md.template`.

**When editing shared docs/skills:** do not hardcode any app-specific value (Team ID, Bundle ID,
domain, email, repo, DNS/DKIM). Add a `{{token}}` and register it in the profile template instead.
Secrets (certificates, API keys) never go in the profile or any shared file.

## skill ↔ docs relative links

Skills reference `docs/process/...` via `../../../docs/process/...`. This resolves **only in the
app layout** (where `.claude/skills/<name>/` and `docs/process/` coexist in the same app tree after
`bootstrap.sh` runs), not within this repo's own tree. Keep skills and their referenced docs synced
together so the links stay valid.

## Adding a New Skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`)
2. Add a symlink: `.claude/skills/<name> -> ../../skills/<name>`
3. Add a row to `skills/README.md`
4. Keep any app-specific value as a `{{token}}` (see profile model above)

## Adding a New Rule

1. Create `rules/flutter-ios/<name>.md`
2. Add a symlink: `.claude/rules/flutter-ios/<name>.md -> ../../../rules/flutter-ios/<name>.md`

## Adding a New Process Doc

1. Create `docs/process/<name>.md`
2. Keep app-specific values as `{{token}}` placeholders with a header note pointing to the profile

## Scope boundary

This repo holds **reusable** Flutter/iOS assets only. App-specific records (filled-in metadata
ledgers, review notes, per-app verification checklists, screenshot images) stay in each app and are
not migrated here.
