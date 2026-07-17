import 'dart:async';

class WearableService {
  static bool _isConnected = false;
  static final StreamController<Map<String, dynamic>> _watchTelemetryController = 
      StreamController<Map<String, dynamic>>.broadcast();

  static bool get isConnected => _isConnected;
  static Stream<Map<String, dynamic>> get watchTelemetryStream => _watchTelemetryController.stream;

  /// Simulates connecting to smart wearable hardware (Wear OS / Apple Watch)
  static Future<bool> connectToWearable() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    _isConnected = true;
    print("⌚ Smart Wearable connection active (Channel bound successfully)");
    return true;
  }

  /// Disconnects from the wearable device
  static void disconnectWearable() {
    _isConnected = false;
    print("⌚ Smart Wearable channel unbound");
  }

  /// Sends a simulated fall event payload from watch sensor registers
  static void simulateFallEvent() {
    if (!_isConnected) {
      print("⚠️ Wearable not connected. Cannot dispatch fall telemetry.");
      return;
    }
    
    final payload = {
      "event_type": "FALL_DETECTED",
      "timestamp": DateTime.now().toIso8601String(),
      "sensor_metrics": {
        "gyro_z_peak": 42.5,
        "impact_acc_g": 6.8,
      },
      "heart_rate_bpm": 114
    };

    _watchTelemetryController.add(payload);
  }

  /// Sends a simulated heart rate anomaly event payload
  static void simulateHeartRateAnomaly(int bpm) {
    if (!_isConnected) return;

    final payload = {
      "event_type": "HEART_RATE_ANOMALY",
      "timestamp": DateTime.now().toIso8601String(),
      "sensor_metrics": {
        "bpm": bpm,
      }
    };

    _watchTelemetryController.add(payload);
  }
}
