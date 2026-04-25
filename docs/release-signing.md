# Release Signing and Notarization

Torr release builds can be unsigned for local testing, or signed and notarized
for public distribution.

## Local Signed Release

Install a Developer ID Application certificate in your login keychain, then run:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_APPLE_ID="you@example.com" \
NOTARY_TEAM_ID="TEAMID" \
NOTARY_PASSWORD="app-specific-password" \
./scripts/build-app.sh release
```

`NOTARY_PASSWORD` should be an app-specific password from Apple ID settings.

## GitHub Actions Secrets

Set these repository secrets before relying on tag-based release automation:

- `MACOS_CERTIFICATE_P12_BASE64`: base64-encoded Developer ID Application `.p12`
- `MACOS_CERTIFICATE_PASSWORD`: password for the `.p12`
- `KEYCHAIN_PASSWORD`: temporary CI keychain password
- `DEVELOPER_ID_APPLICATION`: exact signing identity, for example `Developer ID Application: Your Name (TEAMID)`
- `APPLE_ID`: Apple ID email used for notarization
- `APPLE_TEAM_ID`: Apple Developer team ID
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarization

Create the base64 certificate value on macOS:

```bash
base64 -i DeveloperIDApplication.p12 | pbcopy
```

## Verification

After building:

```bash
codesign --verify --deep --strict --verbose=2 build/Torr.dmg
spctl -a -vv --type open build/Torr.dmg
```
