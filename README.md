# Friturisme App — Complete Setup & Build Guide

## What's in this folder

```
friturisme-app/
├── CLAUDE.md              ← Brain file for Claude Code
├── README.md              ← This file (setup + all prompts)
└── reference/
    ├── ui-showcase.html   ← 12 screen mockups (open in browser)
    └── brandboard.html    ← Full brand board
```

---

## SETUP (do this once before starting Claude Code)

### Step 1: Prerequisites

Make sure you have these installed on your machine:

```bash
# Check Node.js (need 18+)
node --version

# If not installed or too old, install via:
# Mac: brew install node
# Or download from https://nodejs.org

# Check npm
npm --version
```

Install Expo CLI globally:
```bash
npm install -g expo-cli
```

### Step 2: Install Claude Code

```bash
# Native installer (recommended)
curl -fsSL https://claude.ai/install.sh | bash

# Reload shell
source ~/.zshrc    # or source ~/.bashrc

# Verify
claude --version
```

### Step 3: Install Expo Go on your phone

Download "Expo Go" from the App Store (iOS) or Play Store (Android).
This lets you test the app on your actual phone without building.

### Step 4: Create the Expo project

```bash
# Create new Expo project with tabs template
npx create-expo-app@latest friturisme-app --template tabs

# Move into the project
cd friturisme-app
```

### Step 5: Copy files into the project

Copy these files from this package into your project root:
- `CLAUDE.md` → `friturisme-app/CLAUDE.md`
- `reference/` folder → `friturisme-app/reference/`

Your project should now look like:
```
friturisme-app/
├── CLAUDE.md           ← ✅ copied
├── reference/          ← ✅ copied
│   ├── ui-showcase.html
│   └── brandboard.html
├── app/                ← created by Expo
├── package.json
├── tsconfig.json
└── ...
```

### Step 6: Create a Supabase project

1. Go to https://supabase.com and create a free account
2. Create a new project called "friturisme"
3. Copy these values (you'll need them later):
   - Project URL (looks like `https://xxxxx.supabase.co`)
   - Anon public key (starts with `eyJ...`)
4. Go to Authentication → Providers → enable Google and Apple

### Step 7: Start Claude Code

```bash
# From inside the friturisme-app folder
claude
```

Claude Code will read CLAUDE.md automatically. You're ready to go.

### Step 8: Start Expo dev server (in a separate terminal)

Open a second terminal (or split your VS Code terminal):
```bash
cd friturisme-app
npx expo start
```

This shows a QR code. Scan it with your phone camera (iOS) or Expo Go app (Android) to see the app live. Every change Claude Code makes will hot-reload on your phone.

---

## VS Code setup

Yes, you develop in VS Code. Open the project:
```bash
code friturisme-app
```

Recommended extensions:
- **Expo Tools** — Expo autocomplete and config help
- **ES7+ React/Redux/React-Native Snippets** — code snippets
- **Tailwind CSS IntelliSense** — autocomplete for NativeWind classes
- **Prettier** — code formatting

You'll have VS Code open to see the code, a terminal with Claude Code running, and another terminal with `npx expo start`. Your phone shows the live app.

---

## ALL PROMPTS (in order)

### Phase 1: Foundation

#### Prompt 1.1 — Dependencies & config
```
Read CLAUDE.md carefully. Then install and configure:

1. NativeWind v4 (Tailwind CSS for React Native) with our custom colors from CLAUDE.md
2. expo-font with Archivo Black, DM Serif Text, and Outfit fonts 
   (download from Google Fonts, put in assets/fonts/)
3. @supabase/supabase-js for the database
4. expo-secure-store for storing auth tokens
5. expo-location for GPS
6. expo-image for optimized images
7. expo-image-picker for photo uploads
8. @shopify/flash-list for performant lists
9. react-native-reanimated for animations

Set up a lib/supabase.ts client with env vars for EXPO_PUBLIC_SUPABASE_URL 
and EXPO_PUBLIC_SUPABASE_ANON_KEY. Create a .env file with placeholders.

Configure the tailwind.config.js with all Friturisme color tokens.
```

#### Prompt 1.2 — Route structure & layouts
```
Set up the Expo Router file structure from CLAUDE.md:

app/
├── _layout.tsx          (root: load fonts, Supabase auth provider, splash screen)
├── (auth)/
│   ├── _layout.tsx      (stack layout, no tabs, dark bg)
│   ├── login.tsx        (placeholder)
│   └── onboarding.tsx   (placeholder)
├── (tabs)/
│   ├── _layout.tsx      (bottom tab bar: 🏠 Home, 🗺️ Kaart, 🔥 Ontdek, 👤 Profiel)
│   ├── index.tsx        (placeholder)
│   ├── kaart.tsx        (placeholder)
│   ├── ontdek.tsx       (placeholder)
│   └── profiel.tsx      (placeholder)
├── check-in/
│   ├── stap1.tsx        (placeholder)
│   ├── stap2.tsx        (placeholder)
│   ├── stap3.tsx        (placeholder)
│   └── klaar.tsx        (placeholder)
├── frituur/
│   └── [id].tsx         (placeholder)
├── claim/
│   └── [id].tsx         (placeholder)
└── meldingen.tsx        (placeholder)

Style the tab bar: dark background (#1A1410), yellow active indicator (#F2C744),
emoji icons for each tab. Kaart and Ontdek tabs should show a "Binnenkort" 
badge and their screens just say "Komt eraan! 🍟" centered.

The root layout should:
- Load custom fonts and show splash screen until ready
- Set up Supabase auth state listener
- Redirect to (auth)/login if not logged in, (tabs) if logged in
```

#### Prompt 1.3 — Shared components
```
Create reusable components in a components/ folder. 
Look at reference/ui-showcase.html for the exact styling:

- Button: primary (yellow bg, gold shadow, 3D press), ghost (border only), sizes
- Card: dark bg (#302520), subtle border, rounded-[14px], padding
- Input: dark bg, subtle border, yellow border on focus, rounded-[12px]
- Chip: selectable tag (emoji + label), yellow border when selected, rounded-[20px]
- StarRating: interactive 1-5 stars, yellow filled, gray empty, size prop
- Avatar: colored circle with Archivo Black letter initial
- Badge: small colored pill (for "UITBATER", "Geverifieerd", "Binnenkort")
- EmptyState: centered emoji + message + optional CTA button
- Toast: floating notification card (for Friday push, success messages)
- Logo: FRITURISME text in Archivo Black, yellow, with optional size
```

---

### Phase 2: Auth & Onboarding

#### Prompt 2.1 — Database setup
```
Create the full Supabase database. Run these as SQL in the Supabase SQL editor.
Generate the SQL for all tables from CLAUDE.md:
- users, frituren, check_ins, ratings, owner_replies
- Proper foreign keys, indexes, enums
- RLS policies (anyone reads, users write own data, owners reply to own frituur)
- Seed data: 20 frituren in Gent with realistic Flemish names and addresses
- Seed data: 5 test users
- Seed data: 30 check-ins with ratings spread across the frituren

Output the complete SQL so I can paste it into Supabase SQL editor.
Also create TypeScript types in lib/types.ts matching the database schema.
```

#### Prompt 2.2 — Login screen
```
Build the login screen at (auth)/login.tsx.
See the Login screen in reference/ui-showcase.html.

- Dark background (#231B14)
- Big 🍟 emoji centered at top
- FRITURISME in Archivo Black, yellow, large
- Tagline in DM Serif Text italic: "Ge kent uw frituur. Maar kent ge alle frituren?"
- Google sign-in button (white bg, Google logo)
- Apple sign-in button (black bg, Apple logo)
- "Of gebruik e-mail" collapsible section with email + password inputs
- "Registreer" and "Log in" buttons inside the email section
- Footer: "Door verder te gaan accepteer je dat friet superieur is aan patat."

Hook up Supabase Auth for Google and Apple. 
On success: check if user has done onboarding (has favorite_snacks).
If no → navigate to onboarding. If yes → navigate to home tabs.
```

#### Prompt 2.3 — Onboarding
```
Build the onboarding screen at (auth)/onboarding.tsx.
See the Onboarding screen in reference/ui-showcase.html.

- "Welkom bij Friturisme 🍟" heading
- "Wat voor vlees we in de kuip hebben. Of ja, in de frituurpan."
- 4x3 grid of Chip components for snack selection:
  Bicky 🍔, Frikandel 🌭, Viandel 🥩, Stoofvlees 🥘,
  Garnaalkroket 🦐, Kaaskroket 🧀, Loempia 🌯, Mexicano 🔥,
  Gehaktbal 🧆, Kipnuggets 🍗, Hamburger 🍔, Mitraillette 🥖
- Minimum 1 selection required
- "Dat is wie ik ben" button at bottom
- Save selected snacks to users.favorite_snacks in Supabase
- Navigate to home tabs
```

---

### Phase 3: Core App

#### Prompt 3.1 — Home screen
```
Build the home screen at (tabs)/index.tsx.
See the Home screen in reference/ui-showcase.html.

- Greeting based on time of day + user name from Supabase: 
  before 12: "Goeiemorgen", 12-18: "Goeiemiddag", after 18: "Goeienavond"
- Location line: "📍 Gent · Vrijdag" (use expo-location for city, JS for day)
- Big CHECK IN button: full width, yellow, 3D shadow, navigates to check-in/stap1
- "🔥 Trending" section: horizontal FlashList of chips showing most-checked-in 
  snacks this week with growth percentage
- "Recente check-ins" section: vertical FlashList of check-in cards. 
  Each card shows: frituur name, avg score, snack chips, optional text preview, 
  user avatar + name + time ago. Tapping a card goes to frituur/[id].
- Pull to refresh
- Fetch all data from Supabase with proper queries
```

#### Prompt 3.2 — Check-in flow (all 4 screens)
```
Build the complete check-in flow. See Check-in 1/2/3 and Success screens 
in reference/ui-showcase.html.

check-in/stap1.tsx — "Waar zit ge?"
- Request location permission (expo-location)
- Query frituren from Supabase sorted by distance to current GPS position
- Search bar at top for manual lookup
- List: frituur name, address, distance badge (e.g. "350m")
- Tap to select, then "Volgende" button to step 2
- Pass selected frituur to next screen via router params

check-in/stap2.tsx — "Wat eet ge?"
- "Selecteer alles wat in uw bakje zit. Geen oordeel."
- 3-column grid of snack Chips with emoji
- "Sauzen" section below: horizontal scroll of sauce Chips
- Multi-select for both
- "Volgende" button (minimum 1 snack selected)

check-in/stap3.tsx — "Hoe was 't?"
- "Helemaal optioneel. Score wat ge wilt, skip wat ge wilt."
- Block "Over de frituur": StarRating for Friturisme, Service, Prijs-kwaliteit
- Block "Over uw bestelling": dynamically show StarRating for Friet (if friet ordered), 
  Bicky (if bicky ordered), Snacks (if snacks ordered), Sauzen (if sauces ordered)
- Optional TextInput "Nog iets kwijt?"
- Optional photo button (expo-image-picker)
- "Check in" button: save everything to Supabase (check_in + ratings + photo to Storage)

check-in/klaar.tsx — Success
- 🎉 big centered
- "Ingecheckt! [Frituur name], check."
- Milestone: compute total check-ins and show fun message
- Summary card (dark bg, logo, frituur, snacks, score) — this would be the shareable image
- "Deel op Instagram" button (expo-sharing)
- "Naar home" button (router.replace to tabs)
```

#### Prompt 3.3 — Frituur detail page
```
Build the frituur page at frituur/[id].tsx.
See the Frituurpagina screen in reference/ui-showcase.html.

- Get frituur ID from router params, fetch from Supabase
- Hero section: name, "📍 [address]", verified badge if claimed
- Stats row: avg score (computed), total check-ins, total reviews
- Score breakdown: compute average per category from all ratings. 
  Show all 7 categories with StarRating (read-only) and numeric average.
- Top tabs (not bottom tabs): "Check-ins" / "Menu" / "Info"
  - Check-ins tab: FlashList of check-in cards with user info, scores, text
  - Menu tab: list of snacks + sauces this frituur has been reviewed for
  - Info tab: address, phone, opening hours
- Owner replies on check-in cards: Card with green-tinted bg, "UITBATER" Badge, text
- Floating CHECK IN button at bottom: navigates to check-in/stap1 
  with this frituur pre-selected
```

#### Prompt 3.4 — Profile
```
Build the profile screen at (tabs)/profiel.tsx.
See the Profiel screen in reference/ui-showcase.html.

- Avatar component with user initial, random warm color
- Name + "Friturismeur sinds [created_at formatted as 'maart 2026']"
- Three stats cards in a row: X check-ins, X frituren bezocht, X snacks gereviewd
- "Uw reviewer type" card: compute from rating patterns:
  - Lots of bicky reviews + high scores → "De Bicky Connaisseur"
  - Very critical (low avg) → "De Strenge Reviewer"
  - Many different frituren → "De Ontdekkingsreiziger"
  - Lots of sauce ratings → "De Sausarchitect"
  - Default → "De Friturismeur"
  Show type name + fun subtitle + avg score
- "Top snacks" section: list ordered snacks by frequency with avg score
- "Favoriete frituren" section: frituren with most check-ins, with score
- "Recente activiteit" section: timeline of last 10 check-ins
- Settings icon in header: log out button
```

---

### Phase 4: B2B + Extras

#### Prompt 4.1 — Notifications screen
```
Build meldingen.tsx. See Meldingen screen in reference/ui-showcase.html.

For MVP, generate notifications from activity data:
- Query recent check-ins at frituren the user has visited
- Query if any owner has replied to user's check-ins
- Generate fun stat notifications from user's data
- Friday notification: "Het is vrijdag. 🍟 Ge weet wat dat betekent."

Show as a list with different styles per type:
- Icon + colored dot per type
- Unread indicator (bold text, dot)
- Tap notification → navigate to relevant screen

Also set up expo-notifications for push notifications (will need 
to configure for real pushes later, but set up the infrastructure).
```

#### Prompt 4.2 — Claim flow
```
Build claim/[id].tsx. See Claim screen in reference/ui-showcase.html.

- Header: "Claim uw frituur" + frituur name
- Pull real stats from Supabase: "Er staan al X reviews en Y check-ins op uw pagina."
- Two plan cards side by side:
  Gratis: claim, hours, 3 photos
  Premium (€29/maand): + reply, analytics, menu, promotions, verified badge, boost
- "Eerste maand gratis. Opzeggen wanneer ge wilt."
- "Kost minder dan drie pakken friet."
- Claim form: name, role, phone, email
- For MVP: save claim request to Supabase, mark frituur as claimed. 
  Skip payment and SMS verification.
```

---

### Phase 5: Polish

#### Prompt 5.1 — Loading, empty, and error states
```
Go through every screen and add proper states:

Loading: show skeleton screens or "Even geduld, we bakken het klaar..." 
with a 🍟 spinner/animation.

Empty states (use EmptyState component):
- Home no check-ins: "Nog geen check-ins? Da's zoals een friet zonder zout. Doe er iets aan."
- Profile no activity: "Nog niks gereviewed. Uw frituur-DNA is nog een blanco vel."
- Frituur no check-ins: "Nog niemand ingecheckt hier. Zijt gij de eerste?"
- Notifications empty: "Geen meldingen. Stil. Te stil. Ga een friet eten."
- Search no results: "Niks gevonden. Ofwel bestaat het niet, ofwel is het zo underground 
  dat zelfs wij het niet kennen."

Errors: "Er is iets misgelopen. Waarschijnlijk het frituurvet. Probeer opnieuw."
with a retry button.
```

#### Prompt 5.2 — Animations and transitions
```
Add animations to make the app feel polished:
- Screen transitions: smooth slide for stack navigations
- Check-in success: scale-up animation on the 🎉 emoji
- Star ratings: slight bounce when tapping a star
- Chip selection: subtle scale + haptic feedback (expo-haptics)
- Pull to refresh: custom animation
- Cards: subtle press animation (scale 0.98) on touch
- Tab bar: smooth indicator slide between tabs
Use react-native-reanimated for all animations.
```

#### Prompt 5.3 — App icon and splash screen
```
Set up the app icon and splash screen:
- App icon: bold "F" in Archivo Black style, yellow (#F2C744) 
  on dark background (#1A1410), rounded corners
  Create as 1024x1024 PNG, put in assets/
- Splash screen: dark background (#1A1410), centered FRITURISME text 
  in yellow, 🍟 emoji above
- Configure in app.json: icon, splash, adaptiveIcon (Android)
- Set status bar style to light (white text on dark bg)
```

---

### Phase 6: Build & Ship

#### Prompt 6.1 — Prepare for app stores
```
Configure app.json / app.config.ts for production:
- name: "Friturisme"
- slug: "friturisme"
- scheme: "friturisme" (for deep links)
- version: "1.0.0"
- iOS bundleIdentifier: "be.friturisme.app"
- Android package: "be.friturisme.app"
- Proper permissions descriptions for location and camera
- Set up EAS Build configuration (eas.json) with development, 
  preview, and production profiles
```

#### Prompt 6.2 — First build
```
Help me do my first EAS build.
Create an eas.json with three profiles:
- development: internal distribution, includes expo-dev-client
- preview: internal distribution, for testing
- production: app store submission

Show me the exact commands to run:
1. Install EAS CLI
2. Log in to Expo
3. Build for iOS (simulator first)
4. Build for Android (APK for testing)
```

---

## Quick Reference

### Running the app during development
```bash
# Terminal 1: Expo dev server
npx expo start

# Terminal 2: Claude Code
claude

# Scan QR with phone to see live app
```

### Useful commands
```bash
npx expo start              # Start dev server
npx expo start --clear      # Start with cleared cache
npx expo install [package]  # Install Expo-compatible package version
npx expo-doctor             # Check for issues
npx eas build --platform ios --profile preview    # Build iOS preview
npx eas build --platform android --profile preview # Build Android preview
```

### Environment variables (.env)
```
EXPO_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJxxxxxxx
```
