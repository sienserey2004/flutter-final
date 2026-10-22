# 🌿 Aurea Skin — Flutter App

The Flutter mobile app for **Aurea Skin**, a skincare e-commerce system built as a final project.

The app talks to a Flask backend over REST (JSON + JWT bearer tokens):
**[sienserey2004/flutter-final-backend](https://github.com/sienserey2004/flutter-final-backend)**.

```
┌──────────────────┐   HTTP / JSON    ┌───────────────────┐       ┌──────────────────────┐
│  Flutter app     │ ───────────────▶ │  Flask backend    │ ────▶ │ SQLite (dev)         │
│  (this repo)     │   /api/...       │                   │       │ PostgreSQL (deploy)  │
└──────────────────┘ ◀─────────────── └───────────────────┘       └──────────────────────┘
```

---

## Features

| Area              | What's included |
|-------------------|-----------------|
| User management   | Splash, intro, login, register, forgot password, profile, edit profile, account settings, logout |
| Products          | Home feed, categories, product list, search, filters, sorting, product details, recommended products |
| Shopping          | Cart (add / update quantity / remove / clear / summary), wishlist |
| Orders            | Checkout, delivery addresses, shipping options, coupons, order confirmation, order history, order details with status timeline |
| Payments (bonus)  | Bakong **KHQR** QR payment |
| Extras            | Notifications, activity, about, contact, help / support |

---

## Tech Stack

| Layer   | Technology |
|---------|------------|
| Mobile  | Flutter, Dart, `http`, `shared_preferences`, `device_preview` |
| State   | `ChangeNotifier` controllers exposed through `InheritedWidget` scopes (auth, cart, wishlist) |

---

## Project Structure

```
lib/
├── auth/           API client, auth controller, user model
├── core/           theme, formatting, image URL helpers
├── models/         data models (product, cart, order, ...)
├── products/       product & home repositories
├── shopping/       cart & wishlist controllers / repositories
├── orders/         checkout, orders, addresses
├── screens/        all UI screens, grouped by feature
└── widgets/        reusable widgets
test/               unit & widget tests
```

---

## Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.13`)
- The backend running locally — see the [backend README](https://github.com/sienserey2004/flutter-final-backend#quick-start)
- An Android emulator, iOS simulator, or desktop / web target

### Run

```bash
flutter pub get
flutter run
```

The app picks the API address automatically:

| Target                       | Default base URL            |
|------------------------------|-----------------------------|
| Android emulator             | `http://10.0.2.2:5000/api`  |
| iOS simulator, desktop, web  | `http://127.0.0.1:5000/api` |

To use a different server (for example a physical phone on your LAN), pass it at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api
```

In debug builds the app runs inside **DevicePreview** (iPhone 16 Pro Max frame); it is disabled in release builds.

---

## Demo Accounts

Created by the backend's `python seed.py`:

| Role     | Email               | Password   |
|----------|---------------------|------------|
| Customer | `alice@example.com` | `password` |
| Customer | `bob@example.com`   | `password` |
| Customer | `maya@example.com`  | `password` |

Coupons: `WELCOME10` (10% off), `GLOW20` (20% off orders ≥ $80), `FLAT15` ($15 off orders ≥ $60).

---

## Testing

```bash
flutter test
```

Tests cover the cart and wishlist controllers, cart models, product parsing and filtering, and the info screens.
