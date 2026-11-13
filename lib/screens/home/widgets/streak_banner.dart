import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/daruma_model.dart';

class StreakBanner extends StatelessWidget {
  final DarumaModel daruma;

  const StreakBanner({
    Key? key,
    required this.daruma,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Row(
            children: [
              const Icon(Icons.local_fire_department_outlined,
                  size: 26, color: AppColors.shintoVermilion),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${daruma.streakDays} ngày bền bỉ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    daruma.isWobblyStreak
                        ? "⚠️ Daruma đang chao đảo! Học để đứng dậy"
                        : "7 lần ngã, 8 lần đứng dậy",
                    style: TextStyle(
                      fontSize: 12,
                      color: daruma.isWobblyStreak
                          ? Colors.orange
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              )),
            ],
          )),
          const SizedBox(width: 12),
          const Text('継続',
              style: TextStyle(
                  fontFamily: 'DarumaMincho',
                  fontSize: 22,
                  color: AppColors.shintoDarkRed)),
        ],
      ),
    );
  }
}
