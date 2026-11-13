import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/daruma_model.dart';

class VowBanner extends StatelessWidget {
  final DarumaModel daruma;
  final VoidCallback onTap;

  const VowBanner({
    Key? key,
    required this.daruma,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: AppColors.washiCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDFD3BD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                        child: Text(
                      "LỜI NGUYỆN",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.shintoDarkRed,
                        letterSpacing: 1.5,
                      ),
                    )),
                    Icon(
                      daruma.hasLeftEye ? Icons.edit : Icons.add_circle,
                      size: 20,
                      color: AppColors.shintoDarkRed,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "\"${daruma.vowNote}\"",
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
