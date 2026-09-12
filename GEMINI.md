# Mobile App Guidelines (`mmann_mobile`)

<!-- This file is automatically loaded by Antigravity on every prompt in this directory -->

Read and strictly adhere to [MEMORY.md](file:///Users/sakthi/Documents/maruthamann/mmann_mobile/MEMORY.md).

## Core Directives for mmann_mobile
- **Runtime & Framework:** Flutter 3.x (Dart), Riverpod / BLoC, Dio networking.
- **Local Storage:** SQLite (`sqflite` or `drift`) as the primary local offline source of truth.
- **Hierarchy:** Farmer Account ──► Organization (`org`) ──► Multiple Farms (`farm`) ──► Plots (`plot`). Must feature a top-level Farm Switcher.
- **UX Rules:** ≤ 4 taps per log action; bright sunlight contrast mode; ≥ 48dp touch targets; 5 South Indian languages.
- **Authentication:** Mobile OTP (+91). JWT tokens stored in `flutter_secure_storage`. Transparent token refresh via Dio interceptor.
- **Parallel Development:** Must maintain feature parity with `mmann_web` in parallel, unless user specifies "only in mobile app".
