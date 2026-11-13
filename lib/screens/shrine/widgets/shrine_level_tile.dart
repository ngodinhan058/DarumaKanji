import 'package:flutter/material.dart';
import '../../../components/daruma/daruma_wobble_view.dart';
import '../../../models/daruma_model.dart';

class ShrineLevelTile extends StatelessWidget {
  final DarumaModel item;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const ShrineLevelTile({
    Key? key,
    required this.item,
    required this.isUnlocked,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: item.goldAccent.withOpacity(isUnlocked ? 0.6 : 0.2),
          width: 1.5,
        ),
      ),
      color: const Color(0xFF2C2220),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isUnlocked ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                height: 100,
                child: isUnlocked
                    ? DarumaWobbleView(daruma: item, size: 85)
                    : Center(
                        child: Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: item.primaryColor),
                          ),
                          child: Text(
                            "Cấp ${item.levelNumber}",
                            style: TextStyle(
                              color: item.goldAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.topic,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ý nghĩa: ${item.fengShuiMeaning}",
                      style: TextStyle(
                        color: item.goldAccent.withOpacity(0.9),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildEyeBadge("Mắt trái", item.hasLeftEye),
                        const SizedBox(width: 8),
                        _buildEyeBadge("Mắt phải", item.hasRightEye),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEyeBadge(String label, bool isDrawn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDrawn ? Colors.green.withOpacity(0.2) : Colors.black26,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDrawn ? Colors.green : Colors.white24,
          width: 0.8,
        ),
      ),
      child: Text(
        "$label: ${isDrawn ? "✓" : "○"}",
        style: TextStyle(
          color: isDrawn ? Colors.greenAccent : Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
