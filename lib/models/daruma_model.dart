import 'package:flutter/material.dart';

enum DarumaLevelId {
  shorin, // Cấp 1: Chủ Nhập - Đỏ nguyên bản
  fuka, // Cấp 2: Phong Hỏa - Cam lửa / Đỏ thẫm
  shinsei, // Cấp 3: Tâm Tinh - Lục bảo
  taiyo, // Cấp 4: Thái Dương - Hoàng kim
  shinen, // Cấp 5: Tâm Uyên - Lam ngọc
  shiko, // Cấp 6: Tử Quang - Tím hoàng gia / Đen tuyền
}

class DarumaModel {
  final DarumaLevelId id;
  final int levelNumber;
  final String name;
  final String kanjiSymbol;
  final Color primaryColor;
  final Color darkColor;
  final Color goldAccent;
  final String topic;
  final String fengShuiMeaning;

  // Trạng thái người học
  bool hasLeftEye; // Khai nhãn (Lập nguyện)
  bool hasRightEye; // Hoàn nguyện (Hoàn thành)
  String vowNote; // Lời thề nguyện
  double auraProgress; // 0.0 -> 1.0 (Linh Khí)
  int streakDays;
  bool isWobblyStreak; // Chao đảo nếu quên học

  DarumaModel({
    required this.id,
    required this.levelNumber,
    required this.name,
    required this.kanjiSymbol,
    required this.primaryColor,
    required this.darkColor,
    required this.goldAccent,
    required this.topic,
    required this.fengShuiMeaning,
    this.hasLeftEye = false,
    this.hasRightEye = false,
    this.vowNote =
        "Mỗi lần quên Kanji là một lần ngã, hoàn thành ôn tập là một lần đứng dậy!",
    this.auraProgress = 0.0,
    this.streakDays = 1,
    this.isWobblyStreak = false,
  });

  static List<DarumaModel> defaultLevels() {
    return [
      DarumaModel(
        id: DarumaLevelId.shorin,
        levelNumber: 1,
        name: "Chủ Nhập (Shorin)",
        kanjiSymbol: "始",
        primaryColor: const Color(0xFFE83929),
        darkColor: const Color(0xFF8B1A10),
        goldAccent: const Color(0xFFFFD54F),
        topic: "Kanji căn bản (Số đếm, Thiên nhiên, Con người)",
        fengShuiMeaning: "Khởi đầu may mắn, khai mở trí tuệ",
        hasLeftEye: true, // Mẫu ban đầu đã khai nhãn
        auraProgress: 0.65,
        streakDays: 7,
      ),
      DarumaModel(
        id: DarumaLevelId.fuka,
        levelNumber: 2,
        name: "Phong Hỏa (Fūka)",
        kanjiSymbol: "火",
        primaryColor: const Color(0xFFFF5722),
        darkColor: const Color(0xFF9E2C08),
        goldAccent: const Color(0xFFFFE082),
        topic: "Kanji đời sống, Sinh hoạt hằng ngày",
        fengShuiMeaning: "Duy trì ngọn lửa kiên trì bền bỉ",
      ),
      DarumaModel(
        id: DarumaLevelId.shinsei,
        levelNumber: 3,
        name: "Tâm Tinh (Shinsei)",
        kanjiSymbol: "心",
        primaryColor: const Color(0xFF2E7D32),
        darkColor: const Color(0xFF103D14),
        goldAccent: const Color(0xFFA5D6A7),
        topic: "Kanji giao tiếp, Trạng thái, Cảm xúc",
        fengShuiMeaning: "Sức khỏe tâm trí, sự tăng trưởng",
      ),
      DarumaModel(
        id: DarumaLevelId.taiyo,
        levelNumber: 4,
        name: "Thái Dương (Taiyō)",
        kanjiSymbol: "陽",
        primaryColor: const Color(0xFFFFB300),
        darkColor: const Color(0xFF8C5800),
        goldAccent: const Color(0xFFFFF8E1),
        topic: "Kanji công việc, Xã hội, Học tập",
        fengShuiMeaning: "Tài lộc, sự nghiệp & thành công rực rỡ",
      ),
      DarumaModel(
        id: DarumaLevelId.shinen,
        levelNumber: 5,
        name: "Tâm Uyên (Shin'en)",
        kanjiSymbol: "淵",
        primaryColor: const Color(0xFF0288D1),
        darkColor: const Color(0xFF003C61),
        goldAccent: const Color(0xFF81D4FA),
        topic: "Kanji phức hợp, Báo chí, Chuyên ngành",
        fengShuiMeaning: "Trí tuệ sâu sắc, sự điềm tĩnh và thấu suốt",
      ),
      DarumaModel(
        id: DarumaLevelId.shiko,
        levelNumber: 6,
        name: "Tử Quang (Shikō)",
        kanjiSymbol: "極",
        primaryColor: const Color(0xFF311B92),
        darkColor: const Color(0xFF14083E),
        goldAccent: const Color(0xFFFFD700),
        topic: "Kanji cao cấp, Văn học, Cổ điển",
        fengShuiMeaning: "Đạt đến đỉnh cao tinh hoa (Master Kanji)",
      ),
    ];
  }
}
