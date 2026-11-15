# Contributing

1. Fork and create a branch.
2. Write a failing test first, then the fix or feature.
3. Run before pushing:
   ```bash
   dart format lib test
   dart analyze --fatal-infos lib test
   dart test
   ```
4. Add a `CHANGELOG.md` entry and open a PR.

**Security rule:** anything new that gets logged (headers, bodies, URLs, errors)
must go through the masking helpers and have a test proving a secret does not
appear in the output.

## Releasing (maintainer)

1. Bump `version` in `pubspec.yaml` and finalize the changelog.
2. Merge to `main`, then `git tag vX.Y.Z && git push --tags`.
3. `publish.yml` publishes to pub.dev (enable automated publishing once in the package Admin tab).

## Monthly checklist

- Triage issues and PRs
- Merge Dependabot updates (dio and http majors need a compatibility check)
- Check CI on the latest stable Dart and Flutter
