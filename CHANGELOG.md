## 1.1.0

### Security
- Masking now covers JSON **strings** (all `http` client bodies were previously
  logged unmasked), form-encoded bodies, response bodies, URL query parameters
  and URL credentials.
- Release builds no longer log unless `enableInRelease: true`. Previously
  `enableLog` defaulted to `true` and nothing checked the build mode, despite
  the README saying otherwise.
- Added `cookie`, `otp` and `credential` to the default masked keys.

### Fixed
- Dio: concurrent requests to the same URL shared one timer and produced wrong
  durations; each request now carries its own id and start time.
- http: responses were decoded with `String.fromCharCodes`, corrupting UTF-8
  (e.g. Bangla); now decoded as UTF-8.
- http: the response stream is only buffered when the body will be logged and
  the content type is text; binary and large downloads pass through untouched.
- Responses now show the method and URL, and status `0` is shown as failed.

### Added
- Request/response ids (`#1`) to correlate log blocks.
- `showCurl`, `showResponseHeaders`, `excludeUrlPatterns`, `maskValue`,
  `enableInRelease` and a custom `output` sink in `ApiLoggerConfig`.
- `FormData` and multipart summaries, byte body summaries.
- Failure details (Dio exception type, http client errors).
- Tests (~97% line coverage), CI, automated publish workflow, Dependabot.

### Changed
- Pure Dart: removed the `flutter` SDK and unused `rxdart` dependencies.
- Package topics, repository link and docs updated.

## 1.0.0

- Initial release.
