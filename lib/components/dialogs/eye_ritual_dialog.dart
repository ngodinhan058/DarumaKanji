import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

enum EyeRitualType { leftEye, rightEye }

class EyeRitualDialog extends StatefulWidget {
  final EyeRitualType ritualType;
  final String darumaName;
  final Function(String vowText) onCompleted;

  const EyeRitualDialog({
    Key? key,
    required this.ritualType,
    required this.darumaName,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<EyeRitualDialog> createState() => _EyeRitualDialogState();
}

class _EyeRitualDialogState extends State<EyeRitualDialog> {
  final List<Offset> _drawnPoints = [];
  final TextEditingController _vowController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vowController.text = widget.ritualType == EyeRitualType.leftEye
        ? "Mỗi ngày 15 phút, kiên trì không bỏ cuộc!"
        : "Đã hoàn thành xuất sắc mục tiêu cấp độ!";
  }

  @override
  void dispose() {
    _vowController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _drawnPoints.add(details.localPosition);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.ritualType == EyeRitualType.leftEye;
    final title = isLeft
        ? "⛩️ Nghi Thức Khai Nhãn (Mắt Trái)"
        : "✨ Nghi Thức Hoàn Nguyện (Mắt Phải)";
    final subtitle = isLeft
        ? "Tô kín con ngươi mắt trái để gửi gắm lời thề nguyện vào Linh vật Daruma."
        : "Chúc mừng bạn đã chinh phục 100% Kanji! Hãy vẽ mắt phải để hoàn thành ước nguyện.";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.washiBackground,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.shintoDarkRed,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Vòng tròn mắt mô phỏng 3D viền vàng và đỏ
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.kinpaGold, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shintoVermilion.withOpacity(0.2),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  child: CustomPaint(
                    painter: _RitualEyePainter(points: _drawnPoints),
                    child: Center(
                      child: _drawnPoints.isEmpty
                          ? const Text(
                              "Vuốt ngón tay\nvẽ con ngươi",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (isLeft) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "📜 Lời thề nguyện của bạn (Vow Note):",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _vowController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "Nhập quyết tâm của bạn...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.shintoVermilion, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shintoVermilion,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    widget.onCompleted(_vowController.text.trim());
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    isLeft
                        ? "Xác Nhận Khai Nhãn (Lập Nguyện)"
                        : "Thắp Sáng & Hoàn Nguyện",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RitualEyePainter extends CustomPainter {
  final List<Offset> points;
  _RitualEyePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final brushPaint = Paint()
      ..color = AppColors.sumiBlack
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14.0;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], brushPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RitualEyePainter oldDelegate) => true;
}
