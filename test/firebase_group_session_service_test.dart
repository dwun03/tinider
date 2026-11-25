import 'package:flutter_test/flutter_test.dart';
import 'package:tinider/services/firebase_group_session_service.dart';

void main() {
  test('waits for every expected player, including groups of four', () {
    expect(
      FirebaseGroupSessionService.areAllExpectedMembersComplete(
        expectedPlayers: 4,
        completionStates: [true, true, true],
      ),
      isFalse,
    );
    expect(
      FirebaseGroupSessionService.areAllExpectedMembersComplete(
        expectedPlayers: 4,
        completionStates: [true, true, true, false],
      ),
      isFalse,
    );
    expect(
      FirebaseGroupSessionService.areAllExpectedMembersComplete(
        expectedPlayers: 4,
        completionStates: [true, true, true, true],
      ),
      isTrue,
    );
  });

  test('rejects expected player counts outside two through eight', () async {
    final service = FirebaseGroupSessionService();

    await expectLater(
      service.createRoom(gate: 'Gate', budget: 'Regular', expectedPlayers: 1),
      throwsRangeError,
    );
    await expectLater(
      service.createRoom(gate: 'Gate', budget: 'Regular', expectedPlayers: 9),
      throwsRangeError,
    );
  });
}
