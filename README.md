# Seelai — Mobile assistant for partially sighted users

Seelai is a Flutter mobile application that provides object detection, voice assistance, and role-based features for partially sighted users, caretakers, and system administrators. This README focuses on getting developers up and running, explains the repository layout, and documents the cleanup and optimization steps included in this branch.

## Quick start

1. Clone the repository:

```bash
git clone https://github.com/onetwothird/Seelai-App.git
cd seelai_app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run on a connected device or emulator:

```bash
flutter run
```

4. Build a release APK (after verifying everything works):

```bash
flutter build apk --release
```

## Project structure (selected)

- `lib/` — application source code. Role-specific screens live under `lib/roles/{caretaker,mswd,partially_sighted}`.
- `assets/models/` — TFLite models and labels used by object/face detection (`object_detection.tflite`, `face_detection.tflite`).
- `assets/seelai-icons/`, `assets/onboarding_icons/`, `assets/emergency_images/` — optimized image assets (WebP preferred).
- `scripts/` — helper scripts (image optimization, moving models, installing git hooks).
- `.github/workflows/ci.yml` — CI checks (analyze and tests).

## Notes about recent cleanup and asset optimization

- Large PNG/JPEG assets were converted to WebP and originals moved to `assets/_backup_images/` to reduce package size. If you need an original, it is stored there.
- Models were consolidated to `assets/models/`. Update any hardcoded asset paths in code if you add or replace a model.
- `pubspec.yaml` now lists only the asset directories and necessary files to avoid packaging unused files. If your build complains about missing assets, run `flutter pub get` and check `pubspec.yaml` entries.

Scripts added in `scripts/`:
- `optimize_images.py` — batch converts PNG/JPG -> WebP (has dry-run mode).
- `move_models.ps1` — moves models to `assets/models/` (Windows PowerShell).
- `install_git_hooks.ps1` — installs pre-commit hooks that run `flutter analyze`.

## CI

- The GitHub Actions workflow runs `flutter analyze` and the test job (`flutter test --coverage`). The workflow uses `subosito/flutter-action@v2` with `channel: stable`.
- If CI fails on Flutter setup, consider pinning a specific version in the workflow, for example:

```yaml
- uses: subosito/flutter-action@v2
  with:
    channel: stable
# or
    flutter-version: '3.10.5'
```

## Common troubleshooting

- Missing asset errors after optimization: confirm the file exists under `assets/` and that `pubspec.yaml` includes the directory or filename, then run `flutter pub get`.
- Release build errors: run `flutter build apk --release -v` to get verbose logs.
- If git hooks fail locally due to missing PowerShell (`pwsh`) on non-Windows runners, install PowerShell or run commits with `--no-verify` temporarily.

## Development tips

- Run `flutter analyze` before committing. A pre-commit hook is included to help enforce this.
- When changing or replacing models, update `assets/models/` and the code that loads them (search for `object_detection.tflite` or `face_detection.tflite`).
- Keep backups of originals in `assets/_backup_images/` — scripts created during cleanup preserve them.

## Branch & merge notes

- The `cleanup/best-practices` branch consolidated models, optimized assets, and added CI/hooks. It was merged into `main` locally and pushed after validation. Protect `main` with branch rules and require PRs for future changes.

## License & contact

If you need help or want to discuss changes, open an issue or contact the author:

- Email: angelitodecatoriaa@gmail.com
- GitHub: https://github.com/onetwothird

---
Generated/edited by automation to improve developer onboarding. If anything is inaccurate, please open an issue or edit this file.
