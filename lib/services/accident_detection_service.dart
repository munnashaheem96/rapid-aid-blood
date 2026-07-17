import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class AccidentDetectionService {
  static StreamSubscription<UserAccelerometerEvent>? _subscription;
  static bool _isActive = false;
  static double _gThreshold = 4.5; // Shock threshold in G-force (1G = 9.8 m/s^2)

  // Callback to execute when a crash is detected
  static void Function(double forceG)? onCrashDetected;

  static bool get isActive => _isActive;

  /// Starts listening to device accelerometer events to check for high-impact forces.
  static void startListening({double? thresholdG}) {
    if (_isActive) return;
    
    if (thresholdG != null) {
      _gThreshold = thresholdG;
    }

    _isActive = true;
    print("🚗 Accident Detection Service started (Threshold: $_gThreshold G)");

    _subscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // Calculate acceleration magnitude in m/s^2
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Convert to G-force
      final double forceG = magnitude / 9.80665;

      if (forceG >= _gThreshold) {
        print("💥 High G-force detected: ${forceG.toStringAsFixed(2)} G");
        _handleCrash(forceG);
      }
    });
  }

  /// Stops listening to accelerometer events.
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isActive = false;
    print("🚗 Accident Detection Service stopped");
  }

  static void _handleCrash(double forceG) {
    if (onCrashDetected != null) {
      onCrashDetected!(forceG);
    }
  }

  /// Helper tool to simulate a high impact accident for testing.
  static void simulateAccidentForce(double simulatedG) {
    print("🧪 Simulating crash event: $simulatedG G");
    _handleCrash(simulatedG);
  }
}
