import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class KalmanFilter {
  Future<void> stopPredictAndStoreLocation(String userId) async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance
          .collection('predicted_location')
          .doc(userId);

      // Remove the startedPrediction timestamp from Firestore
      await userDoc.update({'startedPrediction': FieldValue.delete()});
      print(
          'Stopped prediction and removed startedPrediction for userId: $userId');

      // Remove all prediction data
      QuerySnapshot predictionsSnapshot =
          await userDoc.collection('predictions').get();

      for (var doc in predictionsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('Removed all stored predictions for userId: $userId');
    } catch (e) {
      print('Error stopping prediction and removing data: $e');
    }
  }

  Future<void> predictAndStoreLocation(String userId) async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance
          .collection('predicted_location')
          .doc(userId);

      // Fetch the user document snapshot
      DocumentSnapshot userSnapshot = await userDoc.get();
      // Initialize or update prediction timestamp
      DateTime startedPrediction;
      if (userSnapshot.exists && userSnapshot.data() != null) {
        var data = userSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('startedPrediction')) {
          startedPrediction = (data['startedPrediction'] as Timestamp).toDate();
        } else {
          startedPrediction = DateTime.now();
          await userDoc.set({'startedPrediction': startedPrediction},
              SetOptions(merge: true));
          print('Started prediction timestamp initialized for userId: $userId');
        }
      } else {
        startedPrediction = DateTime.now();
        await userDoc.set(
            {'startedPrediction': startedPrediction}, SetOptions(merge: true));
        print('Started prediction timestamp initialized for userId: $userId');
      }

      // If prediction is stopped, don't proceed further
      if (startedPrediction == null) {
        print('Prediction stopped. No further action.');
        return;
      }

      // Fetch the last 5 locations from location_history collection
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('location_history')
          .doc(userId)
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> locations = snapshot.docs.map((doc) {
        return {
          'latitude': doc['latitude'],
          'longitude': doc['longitude'],
          'timestamp': (doc['timestamp'] as Timestamp).toDate(),
        };
      }).toList();

      if (locations.length < 5) {
        print(
            'Cannot predict location: Not enough data (at least 5 data points required).');
        return;
      }

      // Prediction logic
      List<double> latitudes =
          locations.map((loc) => loc['latitude'] as double).toList();
      List<double> longitudes =
          locations.map((loc) => loc['longitude'] as double).toList();
      List<double> timeDeltas = List.generate(
        locations.length - 1,
        (i) {
          double delta = locations[i]['timestamp']
              .difference(locations[i + 1]['timestamp'])
              .inSeconds
              .toDouble();
          return delta > 0 ? delta : 1.0; // Avoid zero or negative values
        },
      );

      // Compute velocity
      List<double> latVelocities = List.generate(
        timeDeltas.length,
        (i) => (latitudes[i] - latitudes[i + 1]) / timeDeltas[i],
      );
      List<double> lonVelocities = List.generate(
        timeDeltas.length,
        (i) => (longitudes[i] - longitudes[i + 1]) / timeDeltas[i],
      );

      double avgLatVelocity =
          latVelocities.reduce((a, b) => a + b) / latVelocities.length;
      double avgLonVelocity =
          lonVelocities.reduce((a, b) => a + b) / lonVelocities.length;

      double predictedLatitude = latitudes.first;
      double predictedLongitude = longitudes.first;
      double kalmanErrorLat = 1.0;
      double kalmanErrorLon = 1.0;
      double processNoise = 0.1;
      double measurementNoise = 0.5;

      // Fetch corresponding location data from the other `locations` collection (for isPredicted)
      DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc(userId)
          .get();

      if (locationSnapshot.exists) {
        bool isPredicted = locationSnapshot['isPredicted'] ?? false;

        // Print the value of isPredicted to confirm it's being fetched
        print('isPredicted for userId $userId: $isPredicted');

        // If isPredicted is false, stop prediction
        if (!isPredicted) {
          print(
              'Prediction stopped because isPredicted is false for userId: $userId');
          return;
        } else {
          for (int minute = 1; minute <= 60; minute++) {
            DateTime predictionTimestamp =
                startedPrediction.add(Duration(minutes: minute));

            predictedLatitude += avgLatVelocity * 60;
            predictedLongitude += avgLonVelocity * 60;

            kalmanErrorLat += processNoise;
            kalmanErrorLon += processNoise;

            double kalmanGainLat =
                kalmanErrorLat / (kalmanErrorLat + measurementNoise);
            double kalmanGainLon =
                kalmanErrorLon / (kalmanErrorLon + measurementNoise);

            double measuredLatitude = predictedLatitude;
            double measuredLongitude = predictedLongitude;

            predictedLatitude +=
                kalmanGainLat * (measuredLatitude - predictedLatitude);
            predictedLongitude +=
                kalmanGainLon * (measuredLongitude - predictedLongitude);

            kalmanErrorLat *= (1 - kalmanGainLat);
            kalmanErrorLon *= (1 - kalmanGainLon);

            // Store the prediction in Firestore
            await userDoc.collection('predictions').doc(minute.toString()).set({
              'latitude': predictedLatitude,
              'longitude': predictedLongitude,
              'timestamp': predictionTimestamp,
              'minute': minute,
            });

            print('Prediction for minute $minute stored for userId: $userId');
            print('isPredicted for userId $userId: $isPredicted');
            await Future.delayed(Duration(minutes: 1));
          }
        }
      } else {
        print('No location data found for userId: $userId');
        return;
      }
    } catch (e) {
      print('Error during prediction: $e');
    }
  }
}
