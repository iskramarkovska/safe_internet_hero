import '../data/topic_seed_data.dart';
import '../services/topics_service.dart';

class SeedTopicsFirestore {
  static Future<void> run() async {
    final service = TopicsService();
    await service.seedCategories(seedCategories);
    await service.seedTopics(seedTopics);
  }
}