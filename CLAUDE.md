# FRITURISME — Mobile App

> Ge kent uw frituur. Maar kent ge alle frituren?

Friturisme is a Belgian fry shop check-in and review app. Think Untappd, but for frituren. Users check in, rate individual snacks, and discover new fry shops.

## Tech Stack

- **Framework:** Expo (React Native) with Expo Router for file-based navigation
- **Language:** TypeScript
- **Styling:** NativeWind (Tailwind CSS for React Native)
- **Database:** Supabase (PostgreSQL + Auth + Realtime + Storage)
- **Auth:** Supabase Auth with Google and Apple social login
- **Maps:** react-native-maps + expo-location for GPS
- **Push notifications:** expo-notifications
- **Image handling:** expo-image-picker + expo-image
- **OTA updates:** expo-updates (bug fixes without App Store review)
- **Build & submit:** EAS Build + EAS Submit

---

## Branding

### Colors (configure in NativeWind/Tailwind)

| Name | Hex | Token | Usage |
|------|-----|-------|-------|
| Friet Geel | #F2C744 | `friet-geel` | Primary accent, CTAs, active states |
| Frituur Oranje | #E8742A | `frituur-oranje` | Secondary accent, gradients, hover |
| Bicky Rood | #C4342D | `bicky-rood` | Badges, alerts, destructive |
| Stoofvlees Bruin | #5C2E0E | `stoofvlees-bruin` | Text on light backgrounds |
| Frietkot Groen | #2D6B4A | `frietkot-groen` | Success, verified badges, owner replies |
| Mayo Crème | #FFF8E7 | `mayo-creme` | Light backgrounds |
| Kroket Goud | #D4952B | `kroket-goud` | Button shadows, secondary gold |
| Nacht Donker | #1A1410 | `nacht-donker` | Deepest bg, tab bar |
| Nacht Warm | #231B14 | `nacht-warm` | Screen background (warm brown, NOT black) |
| Nacht Card | #302520 | `nacht-card` | Card backgrounds |

### Typography

- **Display / Headings:** Archivo Black (uppercase, letter-spacing: 1-3px)
- **Accent / Quotes:** DM Serif Text Italic
- **Body:** Outfit (weights 300-700)

Load all three as custom fonts via expo-font.

### Design rules

- Dark theme as default. Warm brown (#231B14), NEVER pure black or #000000.
- Cards: #302520 with subtle border (rgba(242,199,68,0.08))
- Buttons: Friet Geel bg + Kroket Goud shadow (3D press effect)
- Border radius: 14px cards, 12px buttons/inputs, 20px chips/tags
- Use emoji everywhere for snack categories, navigation, ratings
- Bottom tab bar: dark (#1A1410), yellow active indicator

---

## Tone of Voice

Friturisme talks like your best friend who knows everything about frituren. Warm, funny, Flemish, never condescending.

### Rules
- Flemish Dutch: "ge" not "je", "zijt" not "bent"
- NEVER em dashes (—) or en dashes (–)
- Playful but not childish
- Reference real Belgian snack culture

### Copy reference

| Context | Copy |
|---------|------|
| Push (Friday) | "Het is vrijdag. Ge weet wat dat betekent." |
| Empty state | "Nog geen check-ins? Da's zoals een friet zonder zout." |
| Error | "Er is iets misgelopen. Waarschijnlijk het frituurvet. Probeer opnieuw." |
| Review prompt | "Hoe was den bicky? Zeg het voort (of zwijg voor altijd)." |
| No results | "Niks gevonden. Ofwel bestaat het niet, ofwel is het zo underground dat zelfs wij het niet kennen." |
| First check-in | "Proficiat! Uw eerste check-in. Het begin van een vettig avontuur." |
| Loading | "Even geduld, we bakken het klaar..." |
| Terms | "Door verder te gaan accepteer je dat friet superieur is aan patat." |
| Milestone | "Dat zijn al 12 check-ins. Ge begint er serieus werk van te maken." |
| Stat joke | "6 bicky's gereviewd deze maand. Obsessie of passie? Wij oordelen niet." |

---

## Navigation (Expo Router)

File-based routing with tab layout:

```
app/
├── _layout.tsx              ← Root layout (fonts, providers, Supabase)
├── (auth)/
│   ├── _layout.tsx          ← Auth layout (no tabs)
│   ├── login.tsx            ← Login screen
│   └── onboarding.tsx       ← Pick favorite snacks
├── (tabs)/
│   ├── _layout.tsx          ← Tab layout (bottom nav)
│   ├── index.tsx            ← Home (feed + check-in button)
│   ├── kaart.tsx            ← Map (post-MVP, disabled)
│   ├── ontdek.tsx           ← Discover (post-MVP, disabled)
│   └── profiel.tsx          ← Profile
├── check-in/
│   ├── stap1.tsx            ← Select frituur
│   ├── stap2.tsx            ← Select snacks + sauces
│   ├── stap3.tsx            ← Give ratings
│   └── klaar.tsx            ← Success + share
├── frituur/
│   └── [id].tsx             ← Frituur detail page
├── claim/
│   └── [id].tsx             ← B2B claim flow
└── meldingen.tsx            ← Notifications
```

### Bottom tabs (4 tabs)
- 🏠 Home — `(tabs)/index`
- 🗺️ Kaart — `(tabs)/kaart` (disabled, show "Binnenkort" badge)
- 🔥 Ontdek — `(tabs)/ontdek` (disabled, show "Binnenkort" badge)
- 👤 Profiel — `(tabs)/profiel`

---

## Screens

### Login
- 🍟 emoji + FRITURISME logo (Archivo Black, yellow)
- Tagline: "Ge kent uw frituur. Maar kent ge alle frituren?"
- Google login button (prominent)
- Apple login button (prominent)
- Email/password collapsible
- Footer: "Door verder te gaan accepteer je dat friet superieur is aan patat."

### Onboarding
- Pick favorite snacks from chip grid with emoji
- 12 options: Bicky 🍔, Frikandel 🌭, Viandel 🥩, Stoofvlees 🥘, Garnaalkroket 🦐, Kaaskroket 🧀, Loempia 🌯, Mexicano 🔥, Gehaktbal 🧆, Kipnuggets 🍗, Hamburger 🍔, Mitraillette 🥖
- "Wat voor vlees we in de kuip hebben. Of ja, in de frituurpan."

### Home
- Greeting based on time: "Goeiemorgen/Goeiemiddag/Goeienavond, [name] 👋"
- "📍 [city] · [weekday]"
- Big CHECK IN button (always visible, sticky)
- Trending snacks: horizontal FlatList with chips (emoji + name + growth %)
- Recent check-ins: vertical FlatList cards (frituur, score, snack tags, user, time)

### Check-in Step 1: "Waar zit ge?"
- GPS suggestions sorted by distance (expo-location)
- Search bar for manual lookup
- List with frituur name, address, distance badge

### Check-in Step 2: "Wat eet ge?"
- "Geen oordeel."
- 3-column grid: emoji + name per snack
- Sauce chips below (horizontal scroll)
- Multi-select, yellow border on selected

### Check-in Step 3: "Hoe was 't?"
- "Score wat ge wilt, skip wat ge wilt."
- Block 1 "Over de frituur" (always): 🏠 Friturisme, 😊 Service, 💰 Prijs-kwaliteit
- Block 2 "Over uw bestelling" (dynamic): only categories matching ordered items
- Star rating per category (1-5, yellow filled)
- Optional text input + photo (expo-image-picker)

### Check-in Success
- 🎉 big
- "Ingecheckt! [Frituur], check."
- Milestone message
- Shareable card preview
- "Deel op Instagram" + "Naar home" buttons

### Frituur Page
- Hero: name, location, verified badge, stats
- Score breakdown: 7 categories with averages
- Tabs (top tabs): Check-ins / Menu / Info
- Check-in cards feed
- Owner replies: green bg, "UITBATER" badge
- Floating CHECK IN button

### Profile
- Avatar: colored circle, Archivo Black initial
- "Friturismeur sinds [month year]"
- Stats: check-ins, frituren, snacks rated
- Reviewer type: "De Bicky Connaisseur" etc.
- Top snacks, favorite frituren, activity timeline

### Claim (B2B)
- "Er staan al X reviews op uw pagina"
- Free vs Premium comparison
- €29/maand, first month free
- "Kost minder dan drie pakken friet"
- Claim form (name, role, phone)

### Notifications
- Different types: Friday toast, trending, owner reply, fun stats, new nearby
- Unread indicator

---

## Rating System

7 categories, some dynamic:

**Always visible:**
- 🏠 Friturisme (authenticity)
- 😊 Service
- 💰 Prijs-kwaliteit

**Dynamic (only if ordered):**
- 🍟 Friet
- 🍔 Bicky
- 🥩 Snacks
- 🥫 Sauzen

---

## Database (Supabase)

### Tables

**users**: id, email, name, avatar_url, favorite_snacks (text[]), reviewer_type, created_at

**frituren**: id, name, address, city, latitude, longitude, google_place_id, phone, opening_hours (jsonb), claimed (bool), claimed_by (FK), plan (free/premium), verified (bool), created_at

**check_ins**: id, user_id (FK), frituur_id (FK), snacks (text[]), sauces (text[]), text, photo_url, created_at

**ratings**: id, check_in_id (FK), category (enum), score (1-5)

**owner_replies**: id, check_in_id (FK), user_id (FK), text, created_at

### RLS
- Anyone reads frituren, check_ins, ratings
- Users create/edit own check_ins and ratings
- Owners reply only on their claimed frituur

---

## File References

- `reference/ui-showcase.html` — 12 interactive screen mockups. THE visual reference.
- `reference/brandboard.html` — Colors, typography, icons, rating system, tone.

---

## Development Rules

- TypeScript strict mode
- Expo Router for all navigation (file-based)
- NativeWind for all styling (Tailwind classes)
- Custom fonts via expo-font (Archivo Black, DM Serif Text, Outfit)
- All text in Flemish Dutch
- Component names in English (CheckInFlow, FrituurCard, ProfileScreen)
- No inline styles, use NativeWind classNames
- Use expo-image instead of React Native Image (better performance)
- Use FlashList instead of FlatList for long lists (better performance)
