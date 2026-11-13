import 'package:flutter/material.dart';
import '../../components/daruma/daruma_orbit_view.dart';
import '../../components/dialogs/eye_ritual_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../models/daruma_model.dart';
import '../shrine/shrine_screen.dart';
import '../study/srs_study_screen.dart';
import 'widgets/aura_progress_bar.dart';
import 'widgets/streak_banner.dart';
import 'widgets/vow_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<DarumaModel> _darumaLevels;
  int _currentLevelIndex = 0;

  @override
  void initState() {
    super.initState();
    _darumaLevels = DarumaModel.defaultLevels();
  }

  DarumaModel get _currentDaruma => _darumaLevels[_currentLevelIndex];

  void _openEyeRitual(EyeRitualType type) {
    showDialog(
      context: context,
      builder: (context) => EyeRitualDialog(
        ritualType: type,
        darumaName: _currentDaruma.name,
        onCompleted: (vowText) {
          setState(() {
            if (type == EyeRitualType.leftEye) {
              _currentDaruma.hasLeftEye = true;
              _currentDaruma.vowNote = vowText;
            } else {
              _currentDaruma.hasRightEye = true;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.shintoVermilion,
              content: Text(
                type == EyeRitualType.leftEye
                    ? "⛩️ Đã hoàn thành Khai Nhãn! Quyết tâm đã khắc ghi vào tâm nhãn."
                    : "✨ Đại Nguyện Thành Công! Daruma đã được thắp sáng rực rỡ.",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onStudyCompleted(double gainedAura) {
    setState(() {
      _currentDaruma.auraProgress =
          (_currentDaruma.auraProgress + gainedAura).clamp(0.0, 1.0);
      if (_currentDaruma.auraProgress >= 1.0 && !_currentDaruma.hasRightEye) {
        _openEyeRitual(EyeRitualType.rightEye);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final daruma = _currentDaruma;
    final canCompleteVow = daruma.hasLeftEye && daruma.auraProgress >= 1;
    final completionColor = daruma.hasRightEye
        ? Colors.green
        : canCompleteVow
            ? AppColors.shintoVermilion
            : AppColors.textMuted;

    return Scaffold(
      backgroundColor: AppColors.washiBackground,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(24) + 36,
        title: Column(
          children: [
            const Text(
              "DARUMA'S VOW",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.shintoDarkRed,
              ),
            ),
            Text(
              daruma.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.temple_buddhist,
                color: AppColors.shintoVermilion),
            tooltip: "Đền Thờ Linh Vật (Bộ sưu tập)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShrineScreen(
                    levels: _darumaLevels,
                    onSelectLevel: (index) {
                      setState(() => _currentLevelIndex = index);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      // 1. Streak Tracker
                      StreakBanner(
                        daruma: daruma,
                      ),
                      const SizedBox(height: 12),

                      // 2. Lời Thề Nguyện (Vow Note Banner)
                      VowBanner(
                        daruma: daruma,
                        onTap: () => _openEyeRitual(EyeRitualType.leftEye),
                      ),
                      const SizedBox(height: 16),
                      const Text('七転び八起き',
                          style: TextStyle(
                              fontFamily: 'DarumaMincho',
                              fontSize: 16,
                              letterSpacing: 5,
                              color: AppColors.shintoDarkRed)),

                      // A closed 3D mesh with orbit controls; thumbnails stay 2D.
                      LayoutBuilder(builder: (context, constraints) {
                        final dollSize =
                            (constraints.maxWidth * 0.92).clamp(200.0, 340.0);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Hào quang tỏa sáng phía sau
                            Container(
                              width: dollSize,
                              height: dollSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    daruma.goldAccent.withOpacity(
                                        0.12 * daruma.auraProgress),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            DarumaOrbitView(
                              daruma: daruma,
                              size: dollSize,
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 4),

                      // 4. Thanh Linh Khí
                      AuraProgressBar(daruma: daruma),
                      const SizedBox(height: 18),

                      // 5. Nút Khai Nhãn / Hoàn Nguyện
                      LayoutBuilder(builder: (context, constraints) {
                        final vertical = constraints.maxWidth < 300 ||
                            MediaQuery.textScalerOf(context).scale(14) > 20;
                        return Flex(
                          direction: vertical ? Axis.vertical : Axis.horizontal,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: vertical
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              flex: 1,
                              fit: vertical ? FlexFit.loose : FlexFit.tight,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: daruma.hasLeftEye
                                        ? Colors.green
                                        : AppColors.shintoVermilion,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(
                                  daruma.hasLeftEye
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: daruma.hasLeftEye
                                      ? Colors.green
                                      : AppColors.shintoVermilion,
                                  size: 18,
                                ),
                                label: Text(
                                  daruma.hasLeftEye
                                      ? "Đã Khai Nhãn"
                                      : "Vẽ Mắt Trái",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: daruma.hasLeftEye
                                        ? Colors.green
                                        : AppColors.shintoVermilion,
                                  ),
                                ),
                                onPressed: daruma.hasLeftEye
                                    ? null
                                    : () =>
                                        _openEyeRitual(EyeRitualType.leftEye),
                              ),
                            ),
                            SizedBox(
                                width: vertical ? 0 : 10,
                                height: vertical ? 10 : 0),
                            Flexible(
                              flex: 1,
                              fit: vertical ? FlexFit.loose : FlexFit.tight,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: daruma.hasRightEye
                                        ? Colors.green
                                        : completionColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(
                                  daruma.hasRightEye
                                      ? Icons.stars
                                      : Icons.radio_button_unchecked,
                                  color: daruma.hasRightEye
                                      ? Colors.green
                                      : completionColor,
                                  size: 18,
                                ),
                                label: Text(
                                  daruma.hasRightEye
                                      ? "Đã Hoàn Nguyện"
                                      : "Vẽ Mắt Phải",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: daruma.hasRightEye
                                        ? Colors.green
                                        : completionColor,
                                  ),
                                ),
                                onPressed: daruma.hasRightEye ||
                                        daruma.auraProgress < 1 ||
                                        !daruma.hasLeftEye
                                    ? null
                                    : () =>
                                        _openEyeRitual(EyeRitualType.rightEye),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (!daruma.hasRightEye && !canCompleteVow) ...[
                        const SizedBox(height: 8),
                        const Text('Đạt 100% để vẽ mắt hoàn nguyện.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                      const SizedBox(height: 14),

                      // 6. Nút Bắt Đầu Ôn Luyện Kanji SRS
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.shintoVermilion,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 52),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.school, size: 22),
                          label: const Text(
                            "Ôn luyện Kanji",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SrsStudyScreen(
                                  levelNumber: daruma.levelNumber,
                                  onFinishSession: (aura) =>
                                      _onStudyCompleted(aura),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ))),
        ),
      ),
    );
  }
}
