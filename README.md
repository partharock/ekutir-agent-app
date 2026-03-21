# ekutir-agent-app

Flutter implementation of the eK Acre Growth agent experience based on the exported Figma screens.

## Included
- App shell with `go_router`
- Mock data and in-memory state
- Auth, home, engagement, support, harvest/procurement, crop plan, and `MISA AI` placeholder flows
- Widget test scaffolding

## Note
This environment did not have a working Flutter SDK, and installing it failed because the machine ran out of disk space during extraction. The repository therefore contains the Flutter app source (`lib/`, `test/`, `pubspec.yaml`), but not the generated `android/` and `ios/` platform folders.

Once Flutter is available locally, run:

```bash
flutter create . --platforms=android,ios
flutter pub get
flutter test
flutter run
```
