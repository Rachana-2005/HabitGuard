# HabitGuard — AI-Based Digital Addiction Monitoring Flutter Application

HabitGuard is a production-grade digital wellbeing and screen-time monitoring application built with Flutter, Kotlin native `UsageStatsManager`, Material 3, and Firebase. It tracks smartphone app usage, categorizes screen time, calculates a mathematically sound addiction risk score (0–100), and sends emergency alerts to a configured guardian when risk reaches high/critical thresholds.

---

## 🌟 Key Features

1. **Native Android Screen-Time Tracking**: Direct integration with Android's `UsageStatsManager` via Kotlin and Flutter `MethodChannel` (`com.habitguard/usage`).
2. **Application Categorization Engine**: High-performance registry mapping 100+ popular global and regional package IDs across 8 categories with heuristic keyword fallback.
3. **Transparent Risk Score Algorithm (0 - 100)**:
   - **LOW (0 - 30)**: Healthy usage under baseline.
   - **MODERATE (31 - 60)**: Moderate screen time with emerging dopamine loops.
   - **HIGH (61 - 80)**: Heavy screen time triggering guardian and local alerts.
   - **CRITICAL (81 - 100)**: Extreme digital addiction risk requiring immediate intervention.
   - Mitigating credit for productive and educational apps (e.g. Duolingo, Coursera, Google Docs).
4. **Cloud Firestore Sync**: Real-time storage of user profiles (`users/{uid}`), daily usage aggregates (`users/{uid}/dailyUsage/{date}`), individual app metrics (`applications/{pkg}`), and FCM push tokens.
5. **Guardian Emergency Notification Architecture**:
   - 24-hour alert cooldown deduplication per calendar day.
   - Secure backend Cloud Function trigger for SMS dispatch (via Twilio/Webhooks) without exposing API keys in client apps.
   - Local high-priority notifications on user device.
6. **Analytics & Interactive Charts**:
   - Weekly Screen Time Bar Chart (`fl_chart`).
   - Risk Score Trajectory Line Chart with risk zone markers.
   - Category Distribution Pie Chart with interactive legends.
7. **Developer & Mock Mode**: Built-in simulator allowing instant testing of LOW, MODERATE, HIGH, and CRITICAL risk states on emulators and non-Android systems.

---

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.47+ & Dart 3.13+
- **Design System**: Material 3 (Light & Dark Theme support)
- **State Management**: Provider
- **Charts**: `fl_chart`
- **Native Android**: Kotlin, `android.app.usage.UsageStatsManager`, `android.app.AppOpsManager`
- **Backend & Cloud**: Firebase Authentication (Google Sign-In), Cloud Firestore, Firebase Cloud Messaging (FCM), Firebase Cloud Functions (Node.js 18)

---

## 📱 Project Structure

```text
habitguard/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml                  # PACKAGE_USAGE_STATS and notification permissions
│       └── kotlin/com/habitguard/habitguard/
│           └── MainActivity.kt                  # Native UsageStatsManager MethodChannel implementation
│
├── lib/
│   ├── main.dart                                # Application entrypoint with multi-provider setup
│   │
│   ├── core/
│   │   ├── algorithms/
│   │   │   └── risk_score_calculator.dart       # Transparent addiction risk calculation engine
│   │   ├── categorization/
│   │   │   └── app_categorizer.dart             # Extensible package-to-category mapping registry
│   │   ├── constants/
│   │   │   └── app_constants.dart               # Thresholds, collection paths, keys
│   │   ├── theme/
│   │   │   └── app_theme.dart                   # Material 3 light/dark themes and RiskColors palette
│   │   └── utils/
│   │       ├── time_formatter.dart              # Duration and timestamp formatters
│   │       └── validators.dart                  # Guardian mobile number and form validators
│   │
│   ├── models/
│   │   ├── app_category.dart                    # Category enum, icons, and theme colors
│   │   ├── application_usage.dart               # Individual application foreground usage model
│   │   ├── daily_usage.dart                     # Aggregated daily screen time and category breakdowns
│   │   ├── risk_assessment.dart                 # Risk evaluation, levels, and AI recommendations
│   │   └── user_model.dart                      # Firestore user profile and guardian contact model
│   │
│   ├── services/
│   │   ├── auth_service.dart                    # Google Sign-In & Firebase Auth with demo fallback
│   │   ├── firestore_service.dart               # User profiles, daily usage, and FCM token storage
│   │   ├── usage_service.dart                   # MethodChannel wrapper for UsageStatsManager
│   │   ├── mock_usage_service.dart              # Simulated usage data for emulator/testing
│   │   ├── notification_service.dart            # Local notifications and FCM channels
│   │   └── guardian_alert_service.dart          # Cooldown manager and backend SMS dispatcher
│   │
│   ├── providers/
│   │   ├── auth_provider.dart                   # Auth lifecycle and guardian setup state
│   │   ├── usage_provider.dart                  # Screen time collection and mock preset toggles
│   │   ├── risk_provider.dart                   # Risk evaluation and guardian alert triggers
│   │   └── history_provider.dart                # Past 7/14/30 days trend analytics
│   │
│   ├── widgets/
│   │   ├── risk_score_gauge.dart                # Animated radial progress gauge
│   │   ├── category_usage_card.dart             # Category screen time card with progress bar
│   │   ├── app_usage_tile.dart                  # Top application ranking tile
│   │   ├── guardian_alert_banner.dart           # Dashboard emergency guardian status card
│   │   └── charts/
│   │       ├── usage_bar_chart.dart             # Daily screen time bar chart
│   │       ├── risk_trend_chart.dart            # Risk score trajectory line chart
│   │       └── category_pie_chart.dart          # Category distribution donut chart
│   │
│   └── screens/
│       ├── splash/splash_screen.dart            # Animated brand entrance & auth routing
│       ├── auth/login_screen.dart               # Google Sign-In & Quick Demo login
│       ├── onboarding/profile_setup_screen.dart # Guardian name, mobile, and alert preferences
│       ├── permission/permission_screen.dart    # Android Usage Access guide & settings launcher
│       ├── main_screen.dart                     # 4-tab shell navigation (Home, History, Insights, Profile)
│       ├── home/home_screen.dart                # Dashboard with risk gauge, categories, and top apps
│       ├── risk_details/risk_details_screen.dart# Deep-dive risk breakdown and habit recommendations
│       ├── history/history_screen.dart          # Historical daily logs with drill-down modal
│       ├── insights/insights_screen.dart        # Graphical analytics and AI insights
│       └── profile/profile_screen.dart          # Guardian editor, mock mode, alert testing, logout
│
├── functions/
│   ├── package.json                             # Cloud Functions dependencies (firebase-admin, twilio)
│   └── index.js                                 # onDailyUsageWritten trigger for Guardian SMS dispatch
│
├── firestore.rules                              # Security rules enforcing strict user data isolation
└── test/
    ├── risk_score_calculator_test.dart          # Tests 2h (LOW), 4h (MOD), 6h (HIGH), 8h+ (CRIT)
    ├── app_categorizer_test.dart                # Tests package classification & heuristic fallback
    ├── time_and_validators_test.dart            # Tests phone regex & duration conversions
    ├── usage_processing_test.dart               # Tests model serialization & sorting
    └── widget_test.dart                         # Smoke tests for custom widgets
```

---

## 🚀 Setup & Installation Guide

### 1. Prerequisites

- Flutter SDK (3.47.0 or newer)
- Android Studio / Android SDK (API Level 21+)
- Java JDK 17+

### 2. Install Dependencies

```powershell
flutter pub get
```

---

## 🔒 Firebase Configuration

### Step 1: Create a Firebase Project
1. Navigate to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Create Project** and name it `HabitGuard`.
3. Enable **Google Analytics** (optional).

### Step 2: Add Android Application
1. In the Project Overview, click the **Android** icon.
2. Enter the Android package name: `com.habitguard.habitguard`.
3. Register your machine's **SHA-1** and **SHA-256** fingerprints:
   ```powershell
   cd android
   ./gradlew signingReport
   ```
   Copy the `SHA1` and `SHA256` keys from the `debug` configuration and paste them into the Firebase Console.
4. Download `google-services.json` and move it to `android/app/google-services.json`.

### Step 3: Enable Authentication
1. Go to **Build > Authentication > Sign-in method**.
2. Enable the **Google** provider and configure the support email.

### Step 4: Enable Cloud Firestore
1. Go to **Build > Firestore Database**.
2. Click **Create Database** and select **Start in production mode**.
3. Deploy the provided `firestore.rules`:
   ```powershell
   firebase deploy --only firestore:rules
   ```

### Step 5: Enable Firebase Cloud Messaging (FCM)
1. Go to **Project Settings > Cloud Messaging**.
2. Ensure Firebase Cloud Messaging API (V1) is enabled.

---

## 🔑 Android Usage Access Permission Guide

Android restricts access to application usage statistics behind a special system permission (`android.permission.PACKAGE_USAGE_STATS`).

When launching HabitGuard on a physical device or emulator, the application will automatically prompt you to grant access:

1. Tap **Grant Usage Access** on the HabitGuard permission screen.
2. Android will open the **Usage Access** settings screen.
3. Locate **HabitGuard** in the list and toggle the switch to **Allow usage tracking**.
4. Press the back button to return to HabitGuard. The app will detect the permission and open the Dashboard.

### Manufacturer-Specific Settings Paths:
- **Google Pixel / Stock Android**: Settings → Apps → Special app access → Usage access → HabitGuard → Allow
- **Samsung One UI**: Settings → Apps → 3 dots menu (top right) → Special access → Usage data access → HabitGuard → Turn On
- **Xiaomi (MIUI / HyperOS)**: Settings → Privacy protection → Special permissions → Usage access → HabitGuard → Allow
- **OnePlus (OxygenOS)**: Settings → Apps → Special app access → Usage access → HabitGuard → Allow

---

## ✉️ Guardian SMS Provider Configuration (Cloud Functions)

To prevent security vulnerabilities and credential leakage, SMS dispatching is executed entirely on the server side via Firebase Cloud Functions.

### 1. Configure Cloud Functions Environment
Navigate to the `functions/` folder:
```powershell
cd functions
npm install
```

### 2. Set SMS Provider Secrets (e.g. Twilio)
Set the required environment variables:
```powershell
firebase functions:config:set twilio.sid="YOUR_TWILIO_ACCOUNT_SID" twilio.token="YOUR_TWILIO_AUTH_TOKEN" twilio.phone="+1XXXXXXXXXX"
```

### 3. Deploy Functions
```powershell
firebase deploy --only functions
```

*Note: In local development or mock mode, SMS dispatch is gracefully simulated in debug logs and recorded in Firestore `users/{uid}/alerts/` without incurring SMS costs.*

---

## 🧪 Testing & Verification

### Running Automated Tests

Run the complete test suite:
```powershell
flutter test
```

All 25 unit and widget test cases cover:
- Risk score calculation (2h → LOW, 4h → MODERATE, 6h → HIGH, 8h+ → CRITICAL).
- Educational/Productivity score mitigation.
- AppCategorizer package database matching and heuristic fallback.
- Mobile number validation regex and time formatting.
- Widget rendering and animation smoke tests.

### Running Static Analysis
```powershell
flutter analyze
```

---

## 💡 Developer Mock Mode

HabitGuard includes a developer mode so you can test all features on any computer or emulator without needing physical Android usage data:

1. In the app, navigate to **Profile > System & Developer Testing**.
2. Toggle **Mock Data Mode** to **ON**.
3. Select a preset scenario:
   - **Low Risk (~1h 45m)**: Duolingo, WhatsApp, Keep. Score: ~18/100 (LOW).
   - **Moderate Risk (~3h 45m)**: YouTube, Instagram, Slack. Score: ~48/100 (MODERATE).
   - **High Risk (~5h 50m)**: Instagram (2h 20m), YouTube, BGMI. Score: ~74/100 (HIGH) — **Triggers Guardian Alert**.
   - **Critical Risk (~8h 30m)**: BGMI (3h 30m), Instagram, Free Fire. Score: ~92/100 (CRITICAL) — **Triggers Emergency Alert**.
4. Tap **Dispatch Test Guardian Alert** to test the alert workflow end-to-end.

---

## 📄 License
MIT License. Built with ❤️ for Digital Wellbeing.
