import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/daruma_model.dart';

class AuraProgressBar extends StatelessWidget {
  final DarumaModel daruma;

  const AuraProgressBar({Key? key, required this.daruma}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                  child: Text(
                "TIẾN ĐỘ HOÀN NGUYỆN",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.textDark,
                ),
              )),
              Text(
                "${(daruma.auraProgress * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.shintoVermilion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: daruma.auraProgress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE0DCD3),
              valueColor: AlwaysStoppedAnimation<Color>(daruma.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
