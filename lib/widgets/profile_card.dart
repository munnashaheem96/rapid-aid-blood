import 'package:flutter/material.dart';
import 'package:rapid_aid/screens/profile_user.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String bloodGroup;
  final String dob;
  final String lastDonated;
  final String location;

  const ProfileCard({
    super.key,
    required this.name,
    required this.bloodGroup,
    required this.dob,
    required this.lastDonated,
    required this.location,
  });

  int calculateAge(String dob) {
    try {
      List<String> parts = dob.split('/');
      DateTime birthDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    int age = calculateAge(dob);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            child: Text(
              bloodGroup,
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 170,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Positioned(
            left: 20,
            top: 20,
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Positioned(
            right: 20,
            top: 20,
            child: Text(
              bloodGroup,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Positioned(
            left: 20,
            top: 50,
            child: Text(
              'Last Donated: $lastDonated',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),

          Positioned(
            left: 20,
            top: 80,
            child: Text(
              'DOB: $dob ($age yrs)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),

          Positioned(
            left: 20,
            top: 110,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileUser(
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'More Info',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

          // 📍 LOCATION
          Positioned(
            left: 20,
            bottom: 20,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
