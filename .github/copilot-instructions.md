# Seelai App - AI Coding Assistant Instructions

## Project Overview
Seelai is a Flutter mobile app for visually impaired users, featuring real-time object detection via YOLO/TensorFlow Lite, voice assistance, and role-based access (Visually Impaired User, Caretaker, MSDWD Admin). Backend uses Firebase for auth, database, storage, and messaging.

## Architecture
- **State Management**: Minimal; uses `ValueNotifier` for auth (e.g., `authService` in `lib/firebase/auth_service.dart`). No global providers.
- **Data Flow**: Services in `lib/firebase/` handle Firebase operations. Role-specific services save detection results to Realtime DB with activity logging.
- **ML Integration**: Controllers in `lib/roles/visually_impaired/screens/scanner/` use `FlutterVision` for YOLO inference on camera streams. Models loaded from `assets/` (e.g., `assets/object_model/seelai-objects.tflite`).
- **UI Structure**: Role-based screens in `lib/roles/{role}/screens/`. Navigation via role selection post-auth.

## Key Patterns
- **Service Pattern**: Firebase services follow CRUD ops with error handling. Example: `ObjectDetectionService.saveDetectedObjects()` mirrors `TextScanService` structure.
- **Controller Pattern**: For ML features, controllers manage camera, model loading, and TTS. Example: `ObjectDetectionController` initializes `FlutterVision`, loads YOLOv8 model with quantization enabled.
- **TTS Integration**: Use Filipino language (`"fil-PH"`) for accurate pronunciation of local terms. Set speech rate to 0.5 for clarity.
- **Activity Logging**: All user actions logged via `ActivityLogsService` for admin monitoring.
- **Asset Management**: ML models and labels in `assets/` subdirs; declare in `pubspec.yaml` under `flutter.assets`.

## Development Workflows
- **Setup**: `flutter pub get` installs deps including Firebase, camera, `tflite_flutter`. Ensure `google-services.json` for Android Firebase.
- **Run**: `flutter run` for device/emulator. For ML, camera permissions required.
- **Build**: `flutter build apk` for Android; `flutter build ios` for iOS. Models increase APK size; consider app bundles.
- **Debug ML**: Use `flutter_vision` for inference; check model paths and quantization settings. Logs via `debugPrint` in controllers.
- **Firebase Config**: Use `DefaultFirebaseOptions` from `lib/core/firebase_options.dart`. Handle duplicate app errors gracefully.

## Conventions
- **Imports**: Relative paths within `lib/`, e.g., `import '../database_service.dart';`.
- **Error Handling**: Try-catch with `debugPrint` for silent fails in async ops.
- **Comments**: Mark thesis-specific fixes with `// THESIS FIX:` for model optimizations.
- **Role Logic**: Separate auth flows per role; caretaker monitors VI user locations via `Geolocator`.
- **Permissions**: Request camera, location, storage via `permission_handler` before features.

## Common Pitfalls
- **Model Loading**: Ensure `quantization: true` and `useGpu: false` for Int8 models to avoid dequantization slowdowns.
- **TTS Pronunciation**: Filipino locale prevents mispronunciation of terms like "Takure".
- **Stream Management**: Properly stop camera streams in `dispose()` to prevent crashes.
- **Firebase Refs**: Use `databaseService.database.ref()` for consistent DB access.

Reference: `README.md` for features; `pubspec.yaml` for deps; `lib/firebase/visually_impaired/object_detection_service.dart` for data persistence patterns.