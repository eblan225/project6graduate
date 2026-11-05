# Connect Google sign-in

The app uses Flutter's `google_sign_in` package for Google identity only. It requests no Drive, Calendar, Gmail, or Workday access. No client secret belongs in this app. Google sign-in does not save schedules to the cloud or authenticate a backend; a future backend must verify ID tokens before trusting identity.

Until OAuth client IDs are supplied, the sign-in screen shows that setup is pending and offers a guest preview. Native builds use Google's account picker; web uses Google's rendered button. Sign-out removes the session-only goals and schedules. Sign-in is explicit on each launch; automatic account restoration is not implemented.

## Google project

1. Create a project at https://console.cloud.google.com/ and configure Google Auth Platform branding, audience, and consent settings for Graduate!.
2. If the app is in testing, add the Google accounts that will test it as test users.
3. Create the OAuth clients for each platform below. The IDs are public configuration, not passwords. Keep client secrets out of the repository.

## Android

Register an Android OAuth client for package `com.example.project6graduate` with the SHA-1 fingerprint of the signing certificate used for that build. Register debug and release fingerprints as appropriate. Choose a final package name before publishing and update both the app and Google registration together.

Also create a Web application OAuth client in the same project. Pass that web client ID as the server client ID (not the Android client ID):

```sh
flutter run -d <android-device> --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

This uses explicit Dart configuration; `google-services.json` and Firebase are not required.

## iPhone / iPad

Create an iOS OAuth client for bundle ID `com.example.project6graduate`.
Add its reversed client ID to `ios/Runner/Info.plist` inside the top-level dictionary:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_IOS_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Replace that placeholder with the real reversed ID from Google. This callback registration is required even when providing the client ID through Dart. Then run:

```sh
flutter run -d <ios-device> --dart-define=GOOGLE_CLIENT_ID=<ios-client-id>
```

macOS additionally requires the native entitlements and URL scheme setup in the plugin documentation; it has not been configured or verified here.

## Web

Create a Web application OAuth client. Add `http://localhost` and `http://localhost:7357` to its Authorized JavaScript origins, and add the deployed HTTPS origin before publishing. This app passes the ID at initialization, so an HTML meta tag is unnecessary.

```sh
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=GOOGLE_CLIENT_ID=<web-client-id>
```

Use the same `--dart-define` arguments when building for release. Windows and Linux native Google sign-in are not supported by this plugin; use the web build there.

## Verify once configured

- Sign in with an allowed test account; confirm the account name/email and the goals screen.
- Cancel the Google dialog; confirm the app remains signed out and can retry.
- Create goals and schedules, sign out, and sign in with another account; confirm the previous session data is gone.
- Check the web origin, Android signing fingerprint, or iOS callback scheme if sign-in fails.

Real Google authentication cannot be verified until the project/client IDs and platform registration exist.

Official integration references:
- https://pub.dev/packages/google_sign_in
- https://pub.dev/packages/google_sign_in_android
- https://pub.dev/packages/google_sign_in_ios
- https://pub.dev/packages/google_sign_in_web
