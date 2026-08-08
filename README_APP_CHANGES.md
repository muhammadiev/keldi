# Keldim app — backend integration

The app now talks to the Django REST backend instead of using fake/simulated
data. Firebase (which was declared but never configured) has been removed.

## Setup
```bash
flutter pub get
flutter run
```

## IMPORTANT: set the backend URL
Open `lib/services/api_service.dart` and set `baseUrl`:
- Android emulator : `http://10.0.2.2:8000`   (default)
- iOS simulator    : `http://127.0.0.1:8000`
- Real device      : `http://<your-computer-LAN-IP>:8000`
- Production       : `https://school.ontest.uz`

Run the Django server so the phone can reach it:
`python manage.py runserver 0.0.0.0:8000`

## Demo login
`teacher1` / `demo12345`  (teachers teacher1..teacher10 all use demo12345)

## What changed
- **lib/services/api_service.dart** (new) — token login, profile, mark-arrival,
  attendance history, ariza submit/history. Stores the token in SharedPreferences
  and sends `Authorization: Token <token>` on every call.
- **lib/services/location_service.dart** (new) — GPS via geolocator with full
  permission handling.
- **login_screen.dart** — real login (was a hardcoded user map). Routes admin
  vs teacher based on the profile's `is_staff`.
- **home.dart** — the KELDIM/KETDIM button now reads real GPS and calls
  `mark-arrival`. The backend checks you're within ~200m of a school; the app
  shows the server's success/too-far message and the real arrival time.
- **pubspec.yaml** — removed firebase_*, added `http` and `geolocator`.
- **main.dart** — removed dead Firebase init imports.
- **AndroidManifest.xml / Info.plist** — location permissions; cleartext HTTP
  allowed for local dev (REMOVE `usesCleartextTraffic` / use https in production).

## Still using demo data (next to wire up)
`ariza.dart`, `ariza_list.dart`, `history.dart` still show demo data — the
ApiService methods (`submitAriza`, `arizaHistory`, `attendanceHistory`) are ready
to drop in.
