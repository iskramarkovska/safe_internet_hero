class CategoryModel {
  final String id;
  final String title;
  final String iconName;
  final String accentColorHex;
  final int order;

  CategoryModel({
    required this.id,
    required this.title,
    required this.iconName,
    required this.accentColorHex,
    required this.order,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      iconName: map['iconName'] ?? '',
      accentColorHex: map['accentColorHex'] ?? '2BBFAA',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'iconName': iconName,
      'accentColorHex': accentColorHex,
      'order': order,
    };
  }
}