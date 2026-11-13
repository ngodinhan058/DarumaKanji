import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/daruma_model.dart';
import 'widgets/shrine_level_tile.dart';

class ShrineScreen extends StatelessWidget {
  final List<DarumaModel> levels;
  final Function(int selectedIndex) onSelectLevel;

  const ShrineScreen({
    Key? key,
    required this.levels,
    required this.onSelectLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1715),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "⛩️ ĐỀN THỜ LINH VẬT (SHRINE)",
          style: TextStyle(
            color: AppColors.kinpaGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final item = levels[index];
          final isUnlocked = index == 0 || levels[index - 1].hasRightEye;

          return ShrineLevelTile(
            item: item,
            isUnlocked: isUnlocked,
            onTap: () {
              onSelectLevel(index);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
