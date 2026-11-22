# Tinider

![Status](https://img.shields.io/badge/Status-Work_in_Progress-orange)
![Course](https://img.shields.io/badge/ICS26011-App_Dev_3-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)

**Tinider** is an offline-first mobile application designed to help University of Santo Tomas (UST) and U-Belt students quickly decide where to eat during short 15-to-30 minute class breaks. 

By enforcing strict gate proximity and utilizing a rapid consensus swiping mechanic, the app cuts down the endless "saan tayo kakain?" debate to under 60 seconds.

> **Note:** This project is currently in **Phase 3 (Development)**. It is being built as the final academic requirement for ICS26011 (Applications Development and Emerging Technologies 3) by Group 1.

---

## The Problem & Target Audience
Students walking out of campus buildings (like St. Raymund's or Roque Ruaño) often have limited cellular data and even less time. Traditional delivery apps have long wait times, and scrolling through standard directories causes decision fatigue. Tinider is built for UST students and dormers who need a fast, offline-capable way to filter nearby food stalls and force a quick group decision.

## Core Features
* **Gate & Budget Filter:** Filters food spots based on your nearest UST exit (Dapitan, P. Noval, Lacson, or España) and your budget tier (Tipid <₱100, Regular ₱100-₱180, Deserve 'Ko To >₱180).
* **Craving Swiper:** A gesture-based card deck. Swipe right to add a spot to your **Cravings List**, swipe left to pass.
* **"Bahala Na" Auto-Pick:** A fallback edge-case mechanism. If a user rejects every card in the deck, the app forcibly assigns a meal to prevent endless looping.
* **Quick Match Logic:**
  * *Solo:* Ranks liked spots after the full filtered deck is swiped; if none are liked, the highest-ranked spot is selected as a fallback.
  * *Group:* Tracks each participant's votes on the same deck. Right swipes score 1 point, super-likes score 2, and ties favor more likes, shorter walks, then cheaper meals.
* **Offline WalkCard:** Displays walking directions, operating hours, and landmarks instantly, powered by local JSON data to survive campus dead zones.

## Architecture

The food-swiping flow uses an MVC-style separation:

* **Models** in `lib/models/` define food spot data.
* **Views** in `lib/screens/` render screens, handle presentation gestures, and navigate between screens.
* **Controllers** in `lib/controllers/` coordinate screen state and application
  logic. `FoodSwipeController` manages the swipe session and delegates match
  scoring to `QuickMatchState`.
* **Services** in `lib/services/` handle external data access, including Firebase group sessions.

## Tech Stack
* **Framework:** Flutter (Dart)
* **UI Dependencies:** `flutter_card_swiper`
* **Data & State:** Local JSON (Offline-first approach), `shared_preferences`
* **Design:** Figma

## Firebase group sessions

Firestore stores online room IDs, participant progress, swipe votes, and ranked
results only. Food spot records remain in `assets/data/food_dataset.json` and
are not uploaded. The pass-the-phone mode continues to work locally.

To enable online rooms:

1. Create a Firebase project and register the Android/iOS app IDs.
2. Install the Firebase CLI and FlutterFire CLI, then run
   `flutterfire configure --project=<your-project-id>` from the project root.
3. Enable **Anonymous** sign-in and create a Cloud Firestore database in the
   Firebase console.
4. Deploy the room access rules with `firebase deploy --only firestore:rules`.

## 🐯 The Team 
* **Anton** - Project Manager / Lead
* **Dwayne** - Frontend Developer
* **Marc** - Backend & Logic Developer
* **Juan** - UI/UX Designer
* **Jan** - QA & User Testing Lead

## Getting Started
To run this project locally during the development phase:

1. Clone the repository:
   ```bash
   git clone [https://github.com/your-username/tinider-app.git](https://github.com/your-username/tinider-app.git)
