# Maruthamann Mobile App (`mmann_mobile`) — Project Memory & Context

> **Role & Purpose:** This file serves as the permanent architectural memory and context for the mobile client repository (`mmann_mobile`). Any AI assistant or developer working on this repository must strictly adhere to these patterns, UI/UX guidelines, offline-first client architecture, and South Indian agricultural domain requirements.

---

## 1. Project Overview & Mission

- **Project:** **Maruthamann (மருதமண்)** — Mobile App for South Indian Agriculture.
- **Repository:** `mmann_mobile`.
- **Target OS:** Android (APK / Play Store) & iOS.
- **Primary Hardware Target:** Budget Android smartphones (Android 9+, 2GB RAM) commonly used by farmers in rural Tamil Nadu, Andhra Pradesh, Telangana, Karnataka, and Kerala.
- **Key UX Requirements:**
  - **100% Offline Capability:** Operates in rural field conditions with zero network connectivity. All reads and writes target local SQLite first.
  - **Farmer-First Ergonomics:** Maximum 4 taps for any log entry (irrigation, spraying, harvest, expense). Large touch targets (≥ 48×48 dp).
  - **High Contrast:** UI readable under bright direct sunlight in agricultural fields.
  - **Multilingual:** Instant runtime switching across 5 South Indian languages (Tamil, Telugu, Kannada, Malayalam, and English).

---

## 2. Technology Stack & Client Architecture

| Layer | Technology | Details |
|---|---|---|
| **Framework** | **Flutter 3.x with Dart** | Cross-platform mobile development for Android & iOS. |
| **Architecture** | **Feature-first Clean Architecture** | `lib/core/`, `lib/features/auth/`, `lib/features/farm/`, etc. |
| **State Management** | **Riverpod** (or BLoC) | Reactive, testable, and compile-safe state management. |
| **Networking** | **Dio** | Configured with `AuthInterceptor` for Bearer token injection and automatic 401 token refresh. |
| **Secure Storage** | **`flutter_secure_storage`** | Stores JWT access tokens (15-min TTL) and refresh tokens (60-day TTL) in Android KeyStore / iOS Keychain. |
| **Key-Value Cache** | **`shared_preferences`** | Stores non-sensitive preferences like chosen language code and theme settings. |
| **Local Database** | **SQLite (`sqflite` or `drift`)** | The **source of truth** during the farmer's session. Syncs with `mmann_service` using standard revision envelopes. |
| **Localization (i18n)** | **Flutter Localization / ARB** | Full support for `ta`, `te`, `kn`, `ml`, and `en`. |

---

## 3. Multi-Farm & Organization UX Model

Every farmer can own and operate **multiple physical farms** (e.g. Farm 1 in Thanjavur, Farm 2 in Pollachi):

```
┌─────────────────────────────────────────────────────────────┐
│ 1. FARMER ACCOUNT (app_user)                                │
│    • Logged in via Mobile OTP (+91XXXXXXXXXX)               │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. ORGANIZATION (activeOrg State)                           │
│    • Tenant account (e.g. "Ramu Agri Holdings")             │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. PHYSICAL FARMS (activeFarm State & farmsList State)      │
│    • Prominent Farm Switcher in AppBar:                     │
│      [ 🌾 Farm: Thanjavur Delta Farm ▼ ]                     │
│    • Options: Switch between farms, view all, or + Add Farm │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. PLOTS & CROPS (Filtered by activeFarm)                   │
│    • Plots, expenses, irrigation, and activities            │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. API Endpoints for Module 1

The backend REST API is provided by `mmann_service`:
- `POST /v1/auth/request-otp` — Request 6-digit OTP for 10-digit Indian mobile number.
- `POST /v1/auth/verify-otp` — Verifies OTP, provisions account + default farm if new, returns JWT token pair.
- `POST /v1/auth/refresh` — Rotates refresh token and returns fresh access token.
- `GET /v1/auth/me` — Returns current user profile, active org, and list of farms.
- `GET /v1/farms` — Returns all physical farms belonging to the farmer's active organization.
- `POST /v1/farms` — Creates a new physical farm under the organization with regional area unit support.
