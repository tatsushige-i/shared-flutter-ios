---
name: config-flutter-ios-sync
description: Sync shared Flutter/iOS rules, skills, and docs/process from the shared-flutter-ios repository - detect missing symlinks and create them
---

# Shared Flutter/iOS Config Sync Skill

Sync shared rules, skills, and `docs/process` from the shared-flutter-ios repository to the
current Flutter/iOS app. Detect missing symlinks and create them after user confirmation.

This skill is symmetric to `config-claude-sync` (from shared-claude-code) but owns the
**Flutter/iOS layer** that stacks on top of it: `rules/flutter-ios/`, the Flutter/iOS skills,
and `docs/process/`. App-specific values live in `.claude/flutter-ios-profile.md` and are never
synced.

> **Initial setup**: the first wiring is done by `bootstrap.sh` in shared-flutter-ios, not by this
> skill. This skill performs **incremental** sync of items added to shared-flutter-ios after the
> initial bootstrap.

## Steps

### Step 1: Locate the Shared Repository

1. Search for symlinks under `.claude/rules/flutter-ios/`, `.claude/skills/`, and `docs/process/`.
2. Resolve the shared-flutter-ios repository path from the `readlink` result of found symlinks
   - Rule link example: `../../../shared-flutter-ios/rules/flutter-ios/architecture.md` → extract `shared-flutter-ios` path
   - Skill link example: `../../shared-flutter-ios/skills/release-ios-build` → extract `shared-flutter-ios` path
   - Docs link example: `../../shared-flutter-ios/docs/process/release-workflow.md` → extract `shared-flutter-ios` path
3. If no symlinks are found → display error and exit:

   ```text
   Error: No symlinks to shared-flutter-ios found.
   Initial setup must be done by running shared-flutter-ios/bootstrap.sh from this app's root.
   Example: cd <this app> && bash ../shared-flutter-ios/bootstrap.sh
   ```

4. Verify that `rules/flutter-ios/`, `skills/`, and `docs/process/` directories exist at the
   resolved path. If any do not exist → display error and exit.

### Step 2: Detect Differences

1. Get the list of `.md` files under `rules/flutter-ios/` in shared-flutter-ios.
2. Get the list of directories containing `SKILL.md` under `skills/` in shared-flutter-ios.
3. Get the list of `.md` files under `docs/process/` in shared-flutter-ios.
4. Compare with the current project and detect missing items:
   - **Rules**: no symlink exists at `.claude/rules/flutter-ios/<name>.md`
   - **Skills**: no symlink exists at `.claude/skills/<name>`
   - **Docs**: no symlink exists at `docs/process/<name>.md`

### Step 3: Present Differences and Confirm with User

1. If everything is already synced → display the following and exit:

   ```text
   All Flutter/iOS rules, skills, and docs are already synced.
   ```

2. If there are missing items, display in the following format:

   ```text
   ## Unsynced Items

   ### Rules
   - architecture.md

   ### Skills
   - release-ios-build

   ### Docs (docs/process)
   - app-icon.md

   Would you like to sync these items? Let me know if you want to exclude any.
   ```

3. Branch based on the user's response:
   - Full approval → sync all items
   - Partial exclusion → exclude the specified items and sync the rest

### Step 4: Create Branch

1. Check the current branch with `git branch --show-current`.
2. **If not on main** → skip this step and proceed to Step 5 (assume working on an existing branch).
3. **If on main**:
   - Check for uncommitted changes with `git status --porcelain`
     - If changes exist → display error and exit:

       ```text
       Error: There are uncommitted changes on the main branch. Please commit or stash the changes and run again.
       ```

   - Check if a branch with the same name exists with `git branch --list chore/sync-flutter-ios-rules`
     - If it does not exist → create branch with `git checkout -b chore/sync-flutter-ios-rules`
     - If it exists → create branch with `git checkout -b chore/sync-flutter-ios-rules-YYYYMMDD` (current date)

### Step 5: Create Symlinks

1. Rule sync:
   - Create `.claude/rules/flutter-ios/` directory with `mkdir -p` if it does not exist
   - Get the prefix from the `readlink` result of existing rule symlinks and create new symlinks using the same pattern
   - Example: if an existing link is `../../../shared-flutter-ios/rules/flutter-ios/architecture.md`, create new ones as `../../../shared-flutter-ios/rules/flutter-ios/<name>.md`
2. Skill sync:
   - Get the prefix from the `readlink` result of existing skill symlinks and create new symlinks using the same pattern
   - Example: if an existing link is `../../shared-flutter-ios/skills/release-ios-build`, create new ones as `../../shared-flutter-ios/skills/<name>`
3. Docs sync:
   - Create `docs/process/` directory with `mkdir -p` if it does not exist
   - Get the prefix from the `readlink` result of existing docs symlinks and create new symlinks using the same pattern
   - Example: if an existing link is `../../shared-flutter-ios/docs/process/release-workflow.md`, create new ones as `../../shared-flutter-ios/docs/process/<name>.md`
4. After creating each symlink, verify that the link target resolves correctly (`readlink -f`).

> Note: skill→docs internal links (`../../../docs/process/...`) resolve only in the app layout
> (where `.claude/skills/<name>/` and `docs/process/` coexist). Always sync both skills **and**
> `docs/process` so these links stay valid.

### Step 6: Update Documentation

If new skills were synced in Step 5, update documentation files that list skills. Skip this step if
only rules or docs were synced.

1. Check if `.claude/skills/README.md` exists in the current project
   - If it exists:
     - For each synced skill, check whether the skill name already appears in the file
     - For skills not yet listed, read the `description` from the `SKILL.md` frontmatter in the shared-flutter-ios `skills/<name>/SKILL.md`
     - Append a table row at the end of the existing table: `| \`<name>\` | \`/<name>\` | <description> |`
     - Stage the file with `git add .claude/skills/README.md`
   - If it does not exist: skip
2. Check if `CLAUDE.md` in the project root contains a skills listing (e.g., a table or list mentioning existing skill names)
   - If it contains a skills listing:
     - For each synced skill not yet listed, append an entry matching the existing format
     - Stage the file with `git add CLAUDE.md`
   - If `CLAUDE.md` does not exist or does not contain a skills listing: skip

### Step 7: Verify the Profile Exists

1. Check whether `.claude/flutter-ios-profile.md` exists in the current project.
   - If it does **not** exist → warn the user that shared docs/skills reference `{{token}}`
     placeholders resolved from this profile, and suggest running `bootstrap.sh` again or copying
     `flutter-ios-profile.md.template` from shared-flutter-ios. Do not block the sync.
   - If it exists → no action.

### Step 8: Commit

1. Stage the symlinks created in Step 5 individually (do not use `git add -A` or `git add .`):
   - Rules: `git add .claude/rules/flutter-ios/<name>.md`
   - Skills: `git add .claude/skills/<name>`
   - Docs: `git add docs/process/<name>.md`
   - README / CLAUDE.md staged in Step 6 are already included
2. Commit with `git commit -m "chore: sync shared flutter-ios rules and skills"`
3. If the commit fails (e.g., no staged files), display a warning and proceed to Step 9.

### Step 9: Display Results

Display sync results in the following format:

```text
## Sync Complete

- Branch: <branch name> (newly created / existing)
- Commit: <short commit hash>
- Synced rules: X
  - <filename 1>
- Synced skills: X
  - <skill name 1>
- Synced docs: X
  - <filename 1>
- Updated README: <list of updated files>

You can create a PR with `/git-pr-create`.
```

- Display "You can create a PR with `/git-pr-create`." only when a new branch was created in Step 4
- If running on a branch other than main, display "existing" and omit the PR suggestion
- Display each "Synced ..." section only when that category had items
- Display "Updated README" only when README/CLAUDE.md files were updated in Step 6
