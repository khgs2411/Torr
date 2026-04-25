# Contributing to Torr

Thanks for helping improve Torr.

## Development

Torr is a Swift Package Manager macOS app.

```bash
swift test
swift run Torr
```

Build a release DMG:

```bash
./scripts/build-app.sh release
```

## Pull Requests

- Keep changes focused.
- Add or update tests when behavior changes.
- Run `swift test` before opening a PR.
- Use clear PR descriptions with screenshots for UI changes.

## Commit Style

Use conventional commits where practical:

```text
feat: add dynamic menu bar icon
fix: handle unavailable memory pressure data
docs: clarify install instructions
```
