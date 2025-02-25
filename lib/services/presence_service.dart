import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  Timer? _timer;

  /// Starts updating the user's presence in Firestore every second.
  void startUpdatingPresence() {
    _timer?.cancel(); // Ensure no duplicate timers are running.
    _timer = Timer.periodic(Duration(seconds: 45), (timer) async {
      await _updateUserPresence();
    });
  }

  /// Stops the presence update timer.
  void stopUpdatingPresence() {
    _timer?.cancel();
    _timer = null;
  }

  /// Updates the user's presence in Firestore.
  Future<void> _updateUserPresence() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('locations').doc(user.uid);

        await userDocRef.set(
            {
              'lastOnline': FieldValue.serverTimestamp(),
            },
            SetOptions(
                merge: true)); // Use merge to avoid overwriting other fields.
        print('User presence updated');
      }
    } catch (e) {
      print('Error updating presence: $e');
    }
  }

  /// This method is called when the user enters the app (after logging in).
  Future<void> updatePresenceOnEnter() async {
    await _updateUserPresence(); // Update the presence immediately when the user enters the app.
    startUpdatingPresence(); // Start the periodic updates every 45 seconds.
  }
}
