# Skills

Master skill definitions for Flutter/iOS app development, distributed to consuming apps via
symlinks (see the repository [README](../README.md)).

| Skill | Command | Description |
|---|---|---|
| `config-flutter-ios-sync` | `/config-flutter-ios-sync` | Detect missing symlinks and sync Flutter/iOS rules, skills, and `docs/process` under the app |
| `release-roadmap-scaffold` | `/release-roadmap-scaffold` | Scaffold the 3 release milestones and generic issue skeletons into the target repo (idempotent), from `docs/process/release-roadmap.md` |
| `release-ios-build` | `/release-ios-build <version>` | Bump version, build a signed IPA, and create a release PR after ASC upload |
| `release-notes-generate` | `/release-notes-generate [<tag>]` | Diff merged PRs since the previous release tag, draft Japanese release notes, and create the GitHub Release after approval |
| `review-appstore-guidelines` | `/review-appstore-guidelines` | Fetch App Store Review Guidelines at runtime and cross-check the app's implementation |
