# EnvyEnhance App — What Changed in This Update (targeting v1.3.0)

Builds on v1.2.0. All four items from the "suggested next-update priorities"
list were addressed except the manual QA pass (item 1), which only you can
do on-device.

## 1. Saved Addresses — real CRUD (was a "coming soon" stub)

- New `lib/features/addresses/addresses_screen.dart` + `addresses_providers.dart`.
- List, add, edit, delete, and "set as default" — all backed by the
  `UsersRepository.myAddresses/addAddress/updateAddress/deleteAddress`
  methods and `Address` model that were **already fully built** in
  `misc_repository.dart` / `misc.dart` from a previous session but never
  had a screen wired up. Confirmed these match `users.ts` exactly
  (fullName/phone/street/city/district/postalCode/isDefault).
- Profile → "Saved Addresses" now opens the real screen instead of showing
  a snackbar.
- Add/Edit uses a shared bottom-sheet form (`showAddressFormSheet`), so
  Checkout can reuse the exact same form for "add a new address" later
  if you want that entry point too (not wired in yet — currently Checkout
  only lets you pick a saved address or type one manually inline).

## 2. Gift card redemption at checkout (was purchase-only)

- Checkout now has a "Savings" section with two independent inline code
  fields: coupon (existing) and gift card (new).
- Gift card code is checked via the existing public `GET
  /gift-cards/check/:code` endpoint (`GiftCardsRepository.checkBalance`,
  already built, never called from UI) — this just previews the balance,
  it doesn't debit anything yet.
- **Important architecture note, confirmed by reading `orders.ts` in the
  website repo directly:** the backend does **not** fold gift cards into
  order totals. `POST /orders` has no knowledge of gift cards at all —
  `totalAmount` is computed from subtotal, coupon, loyalty points, and
  delivery fee only. `POST /gift-cards/redeem` is a fully separate,
  standalone balance debit.
- So the flow is: place the order first (server computes the authoritative
  total) → then redeem `min(giftCardBalance, order.totalAmount)` from the
  card as a second API call. If that second call fails (e.g. a race
  drained the balance between check and redeem), **the order still
  stands** — we show a snackbar telling the person to contact support
  rather than pretending it succeeded or blocking navigation to their
  new order.
- This means gift card redemption doesn't actually reduce what the person
  owes on `cod`/`bkash`/`nagad` — it debits their gift card balance
  as a separate transaction. If you want gift cards to functionally
  offset the amount charged (e.g. skip payment collection entirely below
  a threshold), that needs a backend change to `orders.ts` to accept a
  gift card code/amount and factor it into `totalAmount` — this update
  only wires up what the existing backend actually supports.
- Order confirmation/detail screen does **not** show gift-card-applied
  info, because the order record itself has no field for it (the backend
  doesn't store which gift card was used against which order) — the only
  confirmation is the checkout-time snackbar/summary. Worth deciding if
  a backend change to persist this is worth doing later.

## 3. Phase 3 layout polish — Cart, Checkout, Orders

Applied the same "generous whitespace, deliberate hierarchy" treatment
Product Detail already had, to the four screens the original handoff
flagged as "functional and on-theme but not art-directed":

- **Cart**: larger item cards (80px thumbnails vs 72px), item count shown
  above the list, stepper buttons enlarged for easier tapping, summary bar
  padding increased, subtotal promoted to `titleLarge`.
- **Checkout**: fully restructured into clearly separated sections
  (Delivery Address / Payment Method / Savings) each with a serif
  `headlineMedium` heading — previously everything ran together under
  generic `titleLarge` labels with tight spacing. Payment method and
  address selection now use full-width tappable cards with radio
  indicators instead of a bare `RadioListTile` column.
- **Orders list**: cards enlarged, first line item's name shown as a
  preview (e.g. "Rose Cleanser +2 more") so the list is scannable without
  opening each order, total price promoted visually.
- **Order detail**: order number promoted to `displaySmall` (matches the
  serif treatment used for prices/headers elsewhere), items shown in a
  single bordered card with dividers between them instead of loose rows,
  total section given more breathing room.

No design tokens changed — same `context.brand` / `Theme.of(context)`
usage throughout, so dark mode still works automatically on all of it.

## 4. Router / Profile wiring

- New route: `/addresses` (protected, same pattern as `/returns` etc).
- `providers.dart` was **not** changed — `usersRepositoryProvider` already
  existed and already exposed everything needed.

## Files changed or added

```
lib/features/addresses/addresses_screen.dart       (new)
lib/features/addresses/addresses_providers.dart    (new)
lib/features/checkout/checkout_screen.dart         (rewritten)
lib/features/cart/cart_screen.dart                 (rewritten)
lib/features/orders/orders_screen.dart             (rewritten)
lib/features/orders/order_detail_screen.dart       (rewritten)
lib/core/router.dart                               (added /addresses route)
lib/features/profile/profile_screen.dart           (wired Saved Addresses link)
```

Nothing else was touched — no changes to `pubspec.yaml`, `providers.dart`,
models, other repositories, Android config, or CI workflows.

## What was NOT done (still open from the original list)

- **Manual QA pass** (section 2 of the original handoff) — still not done,
  still the cheapest highest-confidence next step. Everything in this
  update compiles by manual review (no Flutter/Dart toolchain available in
  this sandbox — same constraint as before) but hasn't been tapped through
  on a device.
- **Push notifications** — not started.
- **Phase 5 performance pass** — not started.
- **Gift card redemption doesn't reduce the order total** — see the
  detailed note in section 2 above. This is a genuine product decision
  (does "redeem" mean "debit the card as a side transaction" or "actually
  pay for part of the order with it") that needs a backend change either
  way if you want the latter.

## Before you build

This was written without a Flutter toolchain available (same sandbox
constraint noted in the previous handoff). Before tagging a release:

1. `flutter analyze` first — I did careful manual review (brace/paren
   balance, cross-checked every method call against its actual
   definition, checked for the specific nullable-field-smart-cast gotcha
   that bit a previous session per the original handoff's known-fixes
   list) but that's not a substitute for the real compiler.
2. Manually walk through: Profile → Saved Addresses → add one → edit it →
   set a different one default → delete one. Then Checkout with a saved
   address selected, and again with "deliver to a new address."
3. Test gift card redemption at checkout with a real gift card code and
   confirm the balance actually decreases afterward (check Profile → Gift
   Cards).
4. When ready: tag `v1.3.0` and push — `release.yml` takes it from there
   (build-name/build-number come from the tag, not from `pubspec.yaml`,
   so no version bump was needed there).
