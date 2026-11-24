# Revised Plan

1. **Add Firebase online matching:** Initialize Firebase; implement room creation/joining, participant identity, live progress and vote synchronization. Keep the local food dataset.
2. **Finalize shared results:** Count positive votes per spot. When all participants finish, deterministically pick based on scores, walking time, and price.
3. **Fix WalkCard details:** In `lib/screens/swipe_screens.dart`, replace the hardcoded route and landmark text with the selected spot's `streetAddress` and `walkingTimeMinutes`.
4. **Rename budget tiers without changing behavior:** In `lib/screens/setup_screens.dart` and the existing mapping in `lib/screens/swipe_screens.dart`, rename `Thrifty` to `Tipid` and `Special Treat` to `Deserve 'Ko To`. Preserve the existing price thresholds and filtering logic; don't create a new controller.
5. **Verify:** Test the updated labels and WalkCard details, then exercise room joining, synced votes, and shared winner selection across clients.
