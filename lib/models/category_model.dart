class CategoryModel {
  final String id;
  final String title;
  final int order;

  CategoryModel({
    required this.id,
    required this.title,
    required this.order,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'order': order,
    };
  }
}