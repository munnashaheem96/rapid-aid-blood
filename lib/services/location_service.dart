import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getLocation() async {
    await Geolocator.requestPermission();

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}