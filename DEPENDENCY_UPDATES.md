Run `flutter pub outdated` to see packages with newer versions. Below are automatic notes collected when I ran `flutter pub get` earlier.

- Several packages have newer versions available; updating should be done carefully and one-at-time.
- Recommended safe flow:
  1. Run `flutter pub outdated` to view current vs latest.
 2. Update non-major versions first (`pubspec.yaml`), run `flutter pub get`, and run `flutter analyze` and app smoke tests.
 3. For packages with major version bumps, read changelogs before updating.

I can prepare a PR that updates minor/patch releases if you want.
