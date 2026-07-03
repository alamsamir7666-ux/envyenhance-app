# EnvyEnhance Mobile App

Native Flutter app for EnvyEnhance, talking directly to the existing
Render API (`https://envyenhance-api-9j77.onrender.com`) and Clerk for
authentication — same backend and user accounts as the website, custom
mobile UI.

## Stack

- **Flutter** (Dart) — UI framework
- **Riverpod** — state management
- **go_router** — navigation, with auth-gated routes
- **Clerk (`clerk_flutter`)** — authentication, shared with the website
- **Dio** — HTTP client, auto-attaches Clerk session token to every request

## Project structure

```
lib/
  core/
    api/          # Repositories — one per backend resource (products, cart, orders, ...)
    auth/          # AuthService abstraction + Clerk implementation
    models/        # Plain Dart data classes matching backend JSON shapes
    theme/         # App-wide color palette and ThemeData
    widgets/       # Shared widgets (loading/error/empty states, product card, nav shell)
    config.dart    # API base URL, Clerk key
    providers.dart # Riverpod providers wiring repositories together
    router.dart    # go_router route table
  features/
    home/ products/ cart/ checkout/ orders/ wishlist/ reviews/ loyalty/ auth/ profile/
    # Each folder: a *_screen.dart (UI) and *_providers.dart (state) pair
  main.dart        # Clerk bootstrap + Riverpod root + MaterialApp.router
```

## First-time setup in Termux

Install Flutter's dependencies and the SDK itself:

```bash
pkg update && pkg upgrade
pkg install -y git unzip openjdk-17 wget

# Flutter has no official Termux package, so it's installed manually.
# Clone the stable channel directly:
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$HOME/flutter/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

flutter doctor
```

`flutter doctor` will likely flag missing Android toolchain/licenses —
that's expected and fine, since the actual APK build happens on GitHub
Actions, not on your phone. Termux is just for editing code and pushing
to git.

## Getting the code onto your phone

```bash
cd ~
# unzip the project archive I gave you, or clone your own repo once pushed
unzip envyenhance_app.zip
cd envyenhance_app
flutter pub get
```

## Configure Android local build path (only needed if you ever build on-device)

```bash
cp android/local.properties.example android/local.properties
# edit android/local.properties and confirm flutter.sdk points at ~/flutter
```

## Pushing to GitHub (triggers the cloud build)

```bash
cd ~/envyenhance_app
git init
git add .
git commit -m "Initial Flutter app"
git branch -M main
git remote add origin https://github.com/alamsamir7666-ux/envyenhance-app.git
git push -u origin main
```

### One-time: add your Clerk key as a GitHub secret

The build workflow (`.github/workflows/build-apk.yml`) reads
`CLERK_PUBLISHABLE_KEY` from a repository secret so it's not sitting in
plaintext in the workflow file, even though publishable keys are safe to
expose client-side.

1. On GitHub: your repo → **Settings** → **Secrets and variables** →
   **Actions** → **New repository secret**
2. Name: `CLERK_PUBLISHABLE_KEY`
3. Value: `pk_test_aGFyZHktYXJhY2huaWQtNTMuY2xlcmsuYWNjb3VudHMuZGV2JA`
   (swap for your production `pk_live_...` key when you're ready to ship)

## Getting the built APK

After pushing, GitHub Actions builds automatically:

1. Go to your repo → **Actions** tab
2. Open the latest "Build APK" run (takes ~5–10 minutes)
3. Download the `envyenhance-app-release` artifact (a zip containing
   `app-release.apk`)
4. Transfer/download it to your phone and tap to install (you'll need to
   allow "install unknown apps" for whatever browser/file manager you use)

You can also trigger a build manually without pushing new code: **Actions**
tab → **Build APK** workflow → **Run workflow**.

## Known gaps / next steps

- **App icon** is a placeholder monogram — swap in your real logo by
  regenerating `android/app/src/main/res/mipmap-*/ic_launcher.png` at
  48/72/96/144/192px (or use `flutter_launcher_icons` package).
- **Release signing** currently uses the Flutter debug key so CI builds
  work out of the box. Fine for testing/sideloading, but you'll need a
  real keystore before publishing to the Play Store — see
  [Flutter's signing docs](https://docs.flutter.dev/deployment/android#signing-the-app).
- **`clerk_flutter` package API**: I wrote the Clerk integration
  (`lib/core/auth/clerk_auth_service.dart`, `lib/main.dart`,
  `lib/features/auth/sign_in_screen.dart`) based on the package's
  expected shape, but young packages sometimes shift their API between
  versions. If `flutter pub get` / the build fails specifically in one of
  those three files, check https://pub.dev/packages/clerk_flutter for the
  current API and adjust — the rest of the app doesn't touch Clerk
  directly, so the fix stays contained.
- **Photo upload on reviews**: the repository layer
  (`lib/core/api/reviews_repository.dart`) supports multipart photo
  upload, but the write-review UI only submits text for now — add an
  image picker to `WriteReviewSheet` when ready.
- **Saved addresses management**: `UsersRepository` has full CRUD for
  addresses; the Profile screen has a placeholder link for it — build
  the actual address-list/edit screens when needed.
- **Admin dashboard**: intentionally out of scope for this phase, per
  the plan to do core shopping + wishlist/reviews/loyalty first.

## Design notes

The UI is a from-scratch native design (not a copy of the website),
themed around a rose/blush palette matching the "sakura-beauty" branding
found in the codebase, with Playfair Display for headings and Inter for
body text.
