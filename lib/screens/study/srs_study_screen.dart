import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/cards/omamori_card.dart';
import '../../core/theme/app_colors.dart';
import '../../models/kanji_model.dart';

class SrsStudyScreen extends StatefulWidget {
  final int levelNumber;
  final Function(double gainedAura) onFinishSession;

  const SrsStudyScreen({
    Key? key,
    required this.levelNumber,
    required this.onFinishSession,
  }) : super(key: key);

  @override
  State<SrsStudyScreen> createState() => _SrsStudyScreenState();
}

class _SrsStudyScreenState extends State<SrsStudyScreen> {
  late List<KanjiModel> _cards;
  int _currentIndex = 0;
  int _rememberedCount = 0;

  @override
  void initState() {
    super.initState();
    _cards = KanjiModel.sampleLevel1();
  }

  void _gradeCard(int rating) {
    HapticFeedback.lightImpact();
    if (rating >= 2) {
      _rememberedCount++;
    }

    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final auraGained = (_rememberedCount / _cards.length) * 0.25;
    widget.onFinishSession(auraGained);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.washiBackground,
        title: const Text(
          "🎉 Hoàn Thành Bài Ôn Tập!",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.shintoDarkRed),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "⛩️ Bạn đã nuôi dưỡng Daruma lớn thêm một bước!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Text(
                "+${(auraGained * 100).toInt()}% Linh Khí tích lũy\nNhớ đúng: $_rememberedCount / ${_cards.length} Kanji",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.shintoVermilion,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Trở về Đền Thờ",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _cards[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.washiBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Kanji ${_currentIndex + 1} / ${_cards.length}",
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _cards.length,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE0DCD3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.shintoVermilion),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: OmamoriCard(kanji: currentCard),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  const Text(
                    "Đánh giá độ ghi nhớ của bạn:",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSrsButton(
                          label: "Quên\n(1 ngày)",
                          color: Colors.red.shade700,
                          rating: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSrsButton(
                          label: "Khó\n(2 ngày)",
                          color: Colors.orange.shade800,
                          rating: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSrsButton(
                          label: "Nhớ\n(4 ngày)",
                          color: Colors.blue.shade700,
                          rating: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSrsButton(
                          label: "Dễ\n(7 ngày)",
                          color: Colors.green.shade700,
                          rating: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSrsButton(
      {required String label, required Color color, required int rating}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      onPressed: () => _gradeCard(rating),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
