# EnvyEnhance App — v1.4.0 Update Notes

## What's in this update

### 1. Blog article blank-body bug — FIXED
Posts written via the admin's rich text editor are stored as raw HTML,
not the legacy structured block format. The app now renders both (added
`flutter_html`), matching what the website already does.

### 2. Pre-Orders "Unauthorized" bug — backend fix required
This is a **backend** bug (wrong auth check in `preOrders.ts`), not
something fixable from the app alone. See the separate
`envyenhance-website-fixes` zip and its `DEPLOY_INSTRUCTIONS.md` — you
need to deploy that to Render for this to actually stop happening. The
app itself needs no changes for this fix.

### 3. Home screen redesign
Rebuilt to match the website's structure:
- Hero banner ("Glow with purpose")
- Category slider (unchanged, already existed)
- **New:** "Discover Your J-Beauty Glow" — Trending/New Arrivals pill tabs
  (was always both sections stacked; now matches the website's tabbed
  toggle)
- **New:** "Best J-Beauty Products" — Skin Care/Hair Care/Make Up/Body
  Care pill tabs, pulling from the same `homepageTag` filter the website
  uses (`GET /products?homepageTag=best_skin_care` etc.) — no backend
  change needed, that filter already existed and was just unused by the
  app.
- **New:** "Our Promise to You" trust section (three icon+text blocks),
  matching the website's "Why Choose Us" section.

### 4. Push notifications
Full FCM-based system — see the website fixes zip's
`DEPLOY_INSTRUCTIONS.md` for the required one-time Firebase setup (create
project, add `google-services.json` to this app, set up the server side).
**Nothing here will send a single notification until that setup is done**
— but it's safe to release this build either way; it fails gracefully
until then.

What's included on the app side:
- `firebase_core` + `firebase_messaging` + `flutter_local_notifications`
- Requests notification permission on first launch
- Registers this device's token with the backend on sign-in, unregisters
  on sign-out
- Shows a system notification when a push arrives in the foreground
  (FCM only auto-displays when backgrounded/killed)
- Tapping a notification deep-links to the relevant screen (order detail,
  pre-orders) using the `route` the server includes in the payload
- `android/app/build.gradle` only applies the Google Services plugin if
  `google-services.json` is present, so **this build will not fail** even
  before you've done the Firebase setup — it just won't send anything yet

## Files changed or added

```
lib/core/models/blog_post.dart              (handle HTML content shape)
lib/features/blog/blog_article_screen.dart  (render HTML when present)
lib/features/home/home_screen.dart          (rewritten)
lib/features/home/home_providers.dart       (best-by-category provider)
lib/core/api/products_repository.dart       (homepageTag param)
lib/core/api/push_repository.dart           (new)
lib/core/push/push_service.dart             (new)
lib/core/providers.dart                     (pushRepositoryProvider)
lib/core/router.dart                        (pushServiceProvider)
lib/main.dart                               (Firebase init, push wiring)
android/build.gradle                        (google-services classpath)
android/app/build.gradle                    (conditional plugin apply)
android/app/src/main/AndroidManifest.xml    (notification permissions)
pubspec.yaml                                (flutter_html, firebase_*)
```

## Before you build

1. `flutter analyze` first, same as always — no Flutter toolchain was
   available to me to verify this compiles cleanly.
2. **You must add `android/app/google-services.json` yourself** — I
   cannot generate this file, it's tied to your specific Firebase
   project. Without it, the app builds and runs fine, it just won't
   receive push notifications.
3. Deploy the companion website fixes (separate zip) to Render — the
   Pre-Orders bug fix and the push-sending backend both live there.
4. Test order: deploy backend first (safe on its own — the mobile-push
   endpoints just won't do anything until the app update ships and
   Firebase is configured), then ship the app update, then do the
   Firebase setup whenever convenient — push notifications are the one
   piece that can lag behind without breaking anything else.
5. Manually test: open a blog post that was blank before and confirm it
   now shows body text; open Pre-Orders after the backend deploy and
   confirm it loads instead of showing "Unauthorized"; browse the new
   home screen tabs.
