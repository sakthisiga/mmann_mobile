# Mobile App Guidelines (`mmann_mobile`)

<!-- This file is automatically loaded by Antigravity and Gemini CLI on every prompt in this directory -->

Read and strictly adhere to [MEMORY.md](file:///Users/sakthi/Documents/maruthamann/mmann_mobile/MEMORY.md).

## Critical Architectural Guidelines

1. **Stack:** Flutter 3.x with Dart. Feature-first Clean Architecture (`lib/features/`, `lib/core/`).
2. **State Management:** Riverpod (or BLoC) for reactive state.
3. **Local Database & Offline-First:**
   - SQLite (`sqflite` or `drift`) is the single source of truth during offline and active user sessions.
   - All mutations hit local SQLite first; background sync pushes mutations to `mmann_service` via standard revision envelopes.
4. **Multi-Farm Hierarchy & UX:**
   - User ──► Organization (`org`) ──► Multiple Farms (`farm`) ──► Plots (`plot`).
   - Provide an accessible Farm Switcher (`activeFarm`) in the AppBar and dashboard.
5. **Farmer-First Ergonomics:**
   - Maximum 4 taps for any log entry (irrigation, fertilizer, expense, harvest).
   - High-contrast UI for direct sunlight readability in agricultural fields.
   - Minimum 48×48 dp touch targets.
6. **Languages & Regional Units:**
   - 5 South Indian languages: Tamil (`ta`), Telugu (`te`), Kannada (`kn`), Malayalam (`ml`), and English (`en`).
   - Display regional area units (Cent, Acre, Guntha, Ground, Ankanam).
7. **Security:**
   - Store JWT tokens in `flutter_secure_storage`.
   - Dio client with `AuthInterceptor` for automatic Bearer token injection and transparent 401 token refresh via `/v1/auth/refresh`.
   - Never collect or store Aadhaar numbers (DPDP Act 2023).
8. **Parallel Development Parity with Web (`mmann_web`):**
   - Features, screens, and UI changes must be developed in parallel with the web application (`mmann_web`) unless explicitly specified as "only in mobile app".
