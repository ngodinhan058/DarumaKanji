class KanjiModel {
  final String kanji;
  final String hanViet;
  final String onyomi;
  final String kunyomi;
  final String meaningVi;
  final String radicals; // Bộ thủ cấu thành
  final String mnemonicStory; // Câu chuyện ghi nhớ
  final List<String> examples;
  final int level;

  // SRS Spaced Repetition Parameters
  int repetitionCount;
  double intervalDays;
  double easeFactor;
  DateTime nextReviewDate;

  KanjiModel({
    required this.kanji,
    required this.hanViet,
    required this.onyomi,
    required this.kunyomi,
    required this.meaningVi,
    required this.radicals,
    required this.mnemonicStory,
    required this.examples,
    required this.level,
    this.repetitionCount = 0,
    this.intervalDays = 1.0,
    this.easeFactor = 2.5,
    DateTime? nextReviewDate,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now();

  static List<KanjiModel> sampleLevel1() {
    return [
      KanjiModel(
        kanji: "日",
        hanViet: "NHẬT",
        onyomi: "NICHI, JITSU",
        kunyomi: "hi, bi, ka",
        meaningVi: "Mặt trời, ban ngày, ngày",
        radicals: "Bộ Nhật (日)",
        mnemonicStory:
            "Mặt trời hình tròn vẽ thành hình chữ nhật có vạch sáng ở giữa.",
        examples: ["日本 (Nihon) - Nhật Bản", "日曜日 (Nichiyoubi) - Chủ nhật"],
        level: 1,
      ),
      KanjiModel(
        kanji: "木",
        hanViet: "MỘC",
        onyomi: "BOKU, MOKU",
        kunyomi: "ki, ko-",
        meaningVi: "Cây, gỗ",
        radicals: "Bộ Mộc (木)",
        mnemonicStory:
            "Hình ảnh cái cây với thân đứng, rễ cắm sâu và tán lá xòe ngang.",
        examples: ["木曜日 (Mokuyoubi) - Thứ năm", "木 (Ki) - Cái cây"],
        level: 1,
      ),
      KanjiModel(
        kanji: "休",
        hanViet: "HƯU",
        onyomi: "KYUU",
        kunyomi: "yasu(mu)",
        meaningVi: "Nghỉ ngơi",
        radicals: "亻(Nhân đứng - Người) + 木 (Mộc - Cây)",
        mnemonicStory:
            "Người (亻) mệt mỏi đứng tựa vào gốc cây (木) để nghỉ ngơi.",
        examples: [
          "休み (Yasumi) - Nghỉ ngơi / Ngày nghỉ",
          "休日 (Kyuujitsu) - Ngày nghỉ lễ"
        ],
        level: 1,
      ),
      KanjiModel(
        kanji: "山",
        hanViet: "SƠN",
        onyomi: "SAN, SEN",
        kunyomi: "yama",
        meaningVi: "Núi",
        radicals: "Bộ Sơn (山)",
        mnemonicStory: "Hình ảnh ba ngọn núi trùng điệp sừng sững giữa trời.",
        examples: ["富士山 (Fujisan) - Núi Phú Sĩ", "山登り (Yamanobori) - Leo núi"],
        level: 1,
      ),
      KanjiModel(
        kanji: "水",
        hanViet: "THỦY",
        onyomi: "SUI",
        kunyomi: "mizu",
        meaningVi: "Nước",
        radicals: "Bộ Thủy (水)",
        mnemonicStory:
            "Dòng nước uốn lượn chảy mạnh qua các ghềnh đá bắn tia nước xung quanh.",
        examples: ["水曜日 (Suiyoubi) - Thứ tư", "水 (Mizu) - Nước uống"],
        level: 1,
      ),
    ];
  }
}
