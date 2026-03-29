enum QuestionType { multipleChoice, trueFalse }

enum DifficultyLevel { beginner, intermediate, advanced }

enum AgeGroup { kids, tweens, teens }

extension AgeGroupExtension on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.kids:
        return 'Kids (6–9)';
      case AgeGroup.tweens:
        return 'Tweens (10–13)';
      case AgeGroup.teens:
        return 'Teens (14+)';
    }
  }

  static AgeGroup fromString(String value) {
    return AgeGroup.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AgeGroup.kids,
    );
  }
}