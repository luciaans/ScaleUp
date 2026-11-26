<div align="center">

<h1>
  <img src="assets/cats/cat_thumbsup.png" width="112" alt="Meme cat giving a thumbs-up" align="absmiddle" />
  ScaleUp
</h1>

**A daily weight & calorie tracker with a meme cat companion.**

![Version](https://img.shields.io/badge/version-v1.0.0-2563EB)
![License](https://img.shields.io/badge/license-MIT-16A34A)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web-111827)
![Flutter](https://img.shields.io/badge/Flutter-3.50%2B-02569B)

[Install](#install) · [Features](#features) · [AI Food Photo](#ai-food-photo) · [Health Formulas](#health-formulas) · [Architecture](#architecture) · [Development](#development) · [License](#license)

</div>

---

ScaleUp is an **offline-first** mobile & web health tracker built with **Flutter (Material 3)**. Log daily weight in one hand, track 7-day moving averages, calculate safe calorie targets automatically, and log meals from a built-in database of **92 Indonesian everyday foods & drinks**.

- **Offline-first & private.** All weight logs, meal entries, profiles, and goal history stay locally in SQLite ([Drift](https://drift.simonbinder.eu/)) with no login required. Export everything to CSV anytime.
- **Built-in health guardrails.** Computes BMR/TDEE via Mifflin-St Jeor, caps weekly weight loss at `1%` of body weight, enforces minimum daily calories (`1,200 kcal` women / `1,500 kcal` men), and auto-recalibrates whenever weight shifts `>= 2.0 kg`.
- **Meme cat companion.** Transparent die-cut Mochi Neko PNG stickers react across onboarding, daily check-ins, and streak celebrations.

## Install

1. Make sure **Flutter SDK** (`>= 3.47.0`, tested on Flutter `3.50.0` / Dart `3.14.0`) is installed.
2. Clone the repository and install dependencies:

```bash
git clone https://github.com/luciaans/ScaleUp.git
cd ScaleUp
flutter pub get
```

3. Run on an Android/iOS device or emulator, or preview in your browser:

```bash
# Android / iOS
flutter run

# Local Web preview
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

## Features

### Onboarding & User Profile
- 4-step interactive flow: welcome & health disclaimer, personal details, activity level descriptions, and goal selection with calorie preview & estimated target date.
- Supportive validation: height (`100–250 cm`), weight (`25–300 kg`), non-future birth date, and minimum age of `18 years`.
- Previous goals are preserved in local history (`isActive = false`) with exactly one active goal at a time.

### Daily Weight Logging & Trend Charts
- One-handed bottom sheet input: `-/+ 0.1` steppers, precision slider, date picker, and optional notes.
- One unique entry per calendar day (automatic upsert on the same date) plus swipe-to-delete with **Undo**.
- Interactive `fl_chart` graph with **7D / 30D / 90D / All** filters, dashed target line, and a **7-Day Moving Average** trend line.

### Calorie Tracker & 92 Indonesian Foods
- Seeded with **92 common Indonesian foods & beverages** (nasi putih, nasi goreng, bubur ayam, tempe/tahu, ayam bakar, rendang, bakso, soto, gado-gado, kopi susu, es teh manis, etc.).
- Instant search, **All / Favorites / Recent** filters, custom food creation, and fractional servings (`0.25–20` portions).
- Collapsible meal sections (**Breakfast, Lunch, Dinner, Snacks**), one-tap **Copy from Yesterday**, macro progress bars, and a 7-day calorie bar chart.

### Dashboard, Reminders & Accessibility
- `CustomScrollView` + `SliverAppBar` dashboard with circular goal ring, today's weight card, remaining calories, daily streak, contextual tips, and milestone confetti (`7-day` / `30-day` streaks or target weight reached).
- Configurable daily local notification reminders, **System / Light / Dark** theme switcher, `kg` / `lb` unit toggle, CSV export, and safe data reset.
- Minimum `48x48dp` touch targets, semantic labels, overflow-free text scaling up to `1.35x`, and **Reduce Motion** support.

## AI Food Photo

ScaleUp includes optional meal-photo nutrition estimation via `backend/analyze_server.py` powered by `gemini-2.5-flash` (see [docs/food-photo-setup.md](docs/food-photo-setup.md) for Firebase AI Logic notes).

```powershell
# Start the local food-photo analysis proxy
$env:GEMINI_API_KEY="YOUR_API_KEY"
python backend/analyze_server.py
```

The server listens on `http://127.0.0.1:8000/analyze`. Without it, manual food logging still works completely offline. Photo-based nutrition values are estimates and can be edited before saving.

## Health Formulas

1. **BMR (Mifflin-St Jeor):**
   - **Male:** $(10 \times \text{weight}_{\text{kg}}) + (6.25 \times \text{height}_{\text{cm}}) - (5 \times \text{age}) + 5$
   - **Female:** $(10 \times \text{weight}_{\text{kg}}) + (6.25 \times \text{height}_{\text{cm}}) - (5 \times \text{age}) - 161$
2. **TDEE:** $\text{BMR} \times \text{Activity Factor}$ (`1.2` Sedentary · `1.375` Light · `1.55` Moderate · `1.725` Heavy · `1.9` Very Heavy).
3. **Daily Calorie Target:**
   - Safe weekly rate capped at $\min(\text{selected rate},\ 0.01 \times \text{weight}_{\text{kg}})$ with $\Delta E = \frac{\text{safe rate} \times 7700}{7}$.
   - **Lose:** $\max(\text{Floor},\ \text{round}(\text{TDEE} - \Delta E))$ · **Gain:** $\text{round}(\text{TDEE} + \Delta E)$ · **Maintain:** $\text{round}(\text{TDEE})$.
   - Daily calorie floor: **1,200 kcal** (female) and **1,500 kcal** (male); rejects lose targets below **BMI 18.5**.
4. **Default Macro Targets:** Protein $1.6\text{ g/kg}$ ($4\text{ kcal/g}$), Fat $25\%$ of target calories ($9\text{ kcal/g}$), Carbs from remaining calories ($4\text{ kcal/g}$).
5. **7-Day Moving Average:** Arithmetic mean of all logged weights inside the $[t - 6\text{ days},\ t]$ calendar window.

## Architecture

Built with a **Feature-First + Repository Pattern** and pure calculation logic in `domain`:

```text
scale-up/
├── assets/
│   ├── branding/                      # ScaleUp cat logo (PNG & SVG)
│   └── cats/                          # Transparent meme cat PNG stickers
├── backend/
│   └── analyze_server.py              # Optional local proxy for AI meal photo analysis
└── lib/
    ├── main.dart                      # App entry point, id_ID localization, ThemeMode & MediaQuery clamp
    ├── core/
    │   ├── constants/                 # Business constants, 8dp spacing, & UI strings
    │   ├── router/                    # GoRouter (white cat boot screen, onboarding, 4 tabs + FAB)
    │   ├── theme/                     # Clean Slate palette & typography
    │   ├── utils/                     # Formatters, kg/lb conversion, calendar dates, reduce motion
    │   └── widgets/                   # AppCard, MochiCompanion, PrimaryButton, ProgressRing, etc.
    ├── data/
    │   ├── database/                  # 6-table Drift (SQLite) schema, date indexes, & migrations
    │   └── seed/                      # 92 seeded Indonesian foods & drinks
    └── features/
        ├── onboarding/                # HealthCalculator domain & 4-step onboarding flow
        ├── home/                      # Active-date aggregation, streak calculator & Home dashboard
        ├── weight/                    # WeightRepository, WeightAnalytics & trend charts
        ├── calories/                  # CaloriesRepository, AI food photo analyzer & daily meal logs
        ├── profile/                   # ProfileRepository, GoalRepository & ActiveNutritionPlan
        └── settings/                  # Theme, units, notifications, CSV export & data reset
```

## Development

```bash
# Regenerate Drift & Riverpod code after modifying schemas or providers
dart run build_runner build --delete-conflicting-outputs

# Run static analysis
flutter analyze

# Run unit & widget tests
flutter test
```

## Disclaimer

ScaleUp is designed as a daily self-tracking tool and is **not a substitute for professional medical advice, diagnosis, or clinical nutrition counseling**.

## License

[MIT](LICENSE) © [luciaans](https://github.com/luciaans)
