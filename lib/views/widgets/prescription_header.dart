import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrescriptionHeader extends StatelessWidget {
  final String doctorName;

  const PrescriptionHeader({super.key, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital, color: Colors.blue, size: 40),
              const SizedBox(width: 8),
              const Text(
                "GM Hospital",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Text(
            "Dr. $doctorName",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
