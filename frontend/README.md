# Seva Connect Flutter app

The Flutter MVP includes volunteer/NGO registration and login, persistent local
sessions, a volunteer opportunity search/details/application flow, and a
volunteer application-status list, plus NGO opportunity and applicant
management.

## Run locally

Start the backend, then run:

```sh
flutter pub get
flutter run
```

The API base URL is centralized in `lib/core/api_client.dart` and defaults to
`http://localhost:3000/api/`. Override it for another device or emulator with
`--dart-define=API_BASE_URL=http://<backend-host>:3000/api/`. For example, the
Android emulator can reach the development host at `10.0.2.2`.

The session, including the JWT, is persisted with `shared_preferences` for this
MVP. Use platform-secure storage before shipping a production app.
