# Keldim v2 — full rewrite

A modern, responsive Flutter client for the school attendance (keldi/ketdi)
backend. Clean architecture, Material 3, light/dark, adaptive layout
(bottom nav on phones, side rail on tablets/desktop).

## Structure
```
lib/
  core/        theme, responsive helpers, app_state (ChangeNotifier)
  services/    api_service, location_service, storage
  models/      typed models matching the REST responses
  widgets/     reusable UI (AppCard, StatCard, StatusChip, EmptyState, ...)
  features/
    auth/        login
    shell/       adaptive navigation container
    dashboard/   GPS check-in + stats grid + recent list
    attendance/  history
    ariza/       list + submit (bottom-sheet form)
    settings/    profile, theme, server URL, logout
```

## Run
```bash
flutter pub get
flutter run
```

### Point the app at your backend
Either edit `ApiService.defaultBaseUrl` in `lib/services/api_service.dart`,
or change it at runtime in the app: **Sozlamalar → Server manzili**.
- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://127.0.0.1:8000`
- Real device: `http://<computer-LAN-IP>:8000`
- Production: `https://school.ontest.uz`

Run Django so a device can reach it: `python manage.py runserver 0.0.0.0:8000`

Demo login: `teacher1 / demo12345`

## Geolocator version note
`pubspec.yaml` pins `geolocator: ^12.0.0`, which uses the `locationSettings:`
API (see `location_service.dart`). If you switch to geolocator < 11, replace
that call with the older form:
```dart
await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
  timeLimit: const Duration(seconds: 20),
);
```

## CI
`codemagic.yaml` builds both APK and AAB on a Flutter stable (>= 3.27 required by geolocator 12), with
pub/gradle caching and a non-blocking analyze step.

## Notes / next steps
- Token is stored in SharedPreferences. For production, move it to
  `flutter_secure_storage`.
- Cleartext HTTP is enabled for local dev (AndroidManifest `usesCleartextTraffic`,
  iOS `NSAllowsLocalNetworking`). Use HTTPS and remove these in production.
- "Ketdim" (leaving) currently shares the same check-in endpoint; the backend
  can be extended with a mark-departure endpoint when you want separate times.
