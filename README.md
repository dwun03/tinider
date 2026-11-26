# Tinider 

![Status](https://img.shields.io/badge/Status-v1.2_Release-success)
![Course](https://img.shields.io/badge/ICS26011-App_Dev_3-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)

**Tinider** is an offline-first mobile application designed to help University of Santo Tomas (UST) and U-Belt students quickly decide where to eat during short 15-to-30 minute class breaks.

By enforcing strict gate proximity and utilizing a rapid consensus swiping mechanic, the app cuts down the endless "saan tayo kakain?" debate to under 60 seconds.

> Built as the Final Academic Requirement for **ICS26011 (Applications Development and Emerging Technologies 3)** by Group 1 (3CSC).

---

## The Problem & Target Audience
Students walking out of campus buildings (like St. Raymund's or Roque Ruaño) often have limited cellular data and even less time. Traditional delivery apps have long wait times, and scrolling through standard directories causes decision fatigue. Tinider is built for UST students and dormers who need a fast, offline-capable way to filter nearby food stalls and force a quick group decision.

## Core Features
* **Gate & Budget Filter:** Filters food spots based on your nearest UST exit (Dapitan, P. Noval, Lacson, or España) and your budget tier (`Tipid` <₱100, `Regular` ₱100–₱180, `Deserve 'Ko To` >₱180).
* **Craving Swiper:** A custom gesture-driven card deck (`GestureDetector` drag/rotation physics). Swipe right to crave, swipe left to pass.
* **"Bahala Na" Auto-Pick:** Fallback mechanism when a user passes on every card in the deck, automatically selecting the top-ranked spot by walking distance and price so breaks aren't wasted.
* **Quick Match Logic:**
  * *Solo & Pass-the-Phone (Offline):* Supports 1 to 8 players locally. Right swipes score +1, super-likes score +2, and ties break deterministically by unique likes, shortest walk, and lowest meal price.
  * *Online 4-Digit Room Code:* Real-time 2-to-8 player lobby and vote sync via Cloud Firestore transactions and anonymous authentication.
* **Offline WalkCard & Saved Spots (CRUD):** Displays walking directions, street address, and operating hours offline from local JSON, with persistent bookmarking, visit tracking, note editing, and deletion synced via Cloud Firestore (`users/{uid}/savedSpots`).

## Architecture
The codebase follows an MVC-style separation:
* **Models (`lib/models/`):** Strongly typed `FoodSpot` and `PriceRange` JSON parsers.
* **Views (`lib/screens/`, `lib/widgets/`):** Custom neo-brutalist UI screens, swipe physics, and responsive reusable components.
* **Controllers (`lib/controllers/`):** `FoodSwipeController` and `QuickMatchState` managing deck filtering, session state, and deterministic vote ranking.
* **Services (`lib/services/`):** `FirebaseGroupSessionService` (multiplayer rooms) and `SavedSpotsService` (persistent CRUD for saved WalkCards).

## Tech Stack
* **Framework:** Flutter & Dart (`^3.13.0`)
* **UI & Vector Assets:** Material 3, `flutter_svg`, local food stall imagery (`assets/images/Foodspots/`)
* **Data & Backend:** Bundled local JSON (`assets/data/food_dataset.json`), `firebase_core`, `firebase_auth` (Anonymous Sign-In), and `cloud_firestore`
* **Design:** Figma

## Firebase Group Sessions & Persistence
Firestore stores online room IDs, participant progress, swipe votes, ranked results, and user-bookmarked WalkCards (`users/{uid}/savedSpots`). Food spot records remain bundled in `assets/data/food_dataset.json` so Solo and Pass-the-Phone modes work completely offline.

## Unsigned iOS Build
The iOS build runs on a macOS GitHub Actions runner (`Build unsigned iOS IPA` workflow) to produce the unsigned `tinider-ios-unsigned-ipa` artifact without Apple code signing or provisioning.

## The Team (Group 1) 🐯🐯🐯🐯🐯
* **Antonio Buenafe III** — Project Manager / Lead
* **Dwayne Anthony Ilano** — Frontend Developer
* **Marc Stephen Pangan** — Backend & Logic Developer
* **Juan Miguel Quilantang** — UI/UX Designer
* **Jan Enzo Bactad** — QA & User Testing Lead

## Getting Started
1. Clone the repository:
   ```bash
   git clone [https://github.com/dwun03/tinider.git](https://github.com/dwun03/tinider.git)
   cd tinider
   ```
2. Install dependencies and run automated tests:
   ```bash
   flutter pub get
   flutter test
   ```
3. Deploy Firestore security rules (if modifying backend rules):
   ```bash
   firebase deploy --only firestore:rules --project tinider-c6398
   ```
4. Run on a connected Android device or emulator:
   ```bash
   flutter run
   ```