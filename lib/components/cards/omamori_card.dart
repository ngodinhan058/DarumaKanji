import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/kanji_model.dart';

class OmamoriCard extends StatefulWidget {
  final KanjiModel kanji;

  const OmamoriCard({Key? key, required this.kanji}) : super(key: key);

  @override
  State<OmamoriCard> createState() => _OmamoriCardState();
}

class _OmamoriCardState extends State<OmamoriCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isBackVisible = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipController.addListener(() {
      if (_flipController.value >= 0.5 && !_isBackVisible) {
        setState(() => _isBackVisible = true);
      } else if (_flipController.value < 0.5 && _isBackVisible) {
        setState(() => _isBackVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.mediumImpact();
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, child) {
          final angle = _flipController.value * math.pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: _isBackVisible
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackSide(),
                  )
                : _buildFrontSide(),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      width: 290,
      height: 420,
      decoration: BoxDecoration(
        color: AppColors.shintoVermilion,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.kinpaGold, width: 3),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.kinpaAmber),
            ),
            child: const Text(
              "⛩️ 御守 OMAMORI",
              style: TextStyle(
                color: AppColors.shintoDarkRed,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          Text(
            widget.kanji.kanji,
            style: const TextStyle(
              fontSize: 92,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
              fontFamily: 'Noto Serif JP',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.kinpaGold,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              widget.kanji.hanViet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.shintoDarkRed,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.kanji.meaningVi,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              "👆 Chạm để lật xem cách đọc & mẹo nhớ",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      width: 290,
      height: 420,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.washiCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.shintoVermilion, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.kanji.kanji,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Serif JP',
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.kanji.radicals,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.shintoVermilion,
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 6),
          _buildInfoRow("Onyomi:", widget.kanji.onyomi),
          _buildInfoRow("Kunyomi:", widget.kanji.kunyomi),
          const SizedBox(height: 8),
          const Text(
            "💡 Mẹo ghi nhớ (Mnemonic):",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.indigo),
          ),
          Text(
            widget.kanji.mnemonicStory,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF424242), height: 1.3),
          ),
          const SizedBox(height: 10),
          const Text(
            "📖 Ví dụ từ vựng:",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          ...widget.kanji.examples.map(
            (ex) => Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text("• $ex",
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
            ),
          ),
          const Spacer(),
          const Center(
            child: Text(
              "👆 Chạm để quay lại",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.shintoDarkRed),
            ),
          ),
        ],
      ),
    );
  }
}
