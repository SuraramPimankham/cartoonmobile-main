import 'dart:convert';

class CartoonModel {
  final String author;
  final String categories;
  final String createdAt;
  final String day;
  final String description;
  final String id;
  final String imageUrl;
  final String title;
  final String updatedAt;

  CartoonModel({
    required this.author,
    required this.categories,
    required this.createdAt,
    required this.day,
    required this.description,
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.updatedAt,
  });
  CartoonModel copyWith({
    String? author,
    String? categories,
    String? createdAt,
    String? day,
    String? description,
    String? id,
    String? imageUrl,
    String? title,
    String? updatedAt,
  }) {
    return CartoonModel(
      author: author ?? this.author,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      day: day ?? this.day,
      description: description ?? this.description,
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'categories': categories,
      'createdAt': createdAt,
      'day': day,
      'description': description,
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'updatedAt': updatedAt,
    };
  }

  factory CartoonModel.fromMap(Map<String, dynamic> map) {
    return CartoonModel(
      author: map['author'],
      categories: map['categories'],
      createdAt: map['createdAt'],
      day: map['day'],
      description: map['description'],
      id: map['id'],
      imageUrl: map['imageUrl'],
      title: map['title'],
      updatedAt: map['updatedAt'],
    );
  }
  String toJson() => json.encode(toMap());
  factory CartoonModel.fromJson(String source) =>
      CartoonModel.fromMap(json.decode(source));
  @override
  String toString() {
    return 'CartoonModel(author: $author, categories: $categories, createdAt: $createdAt, day: $day, description: $description, id: $id, imageUrl: $imageUrl, title: $title, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartoonModel &&
        other.author == author &&
        other.categories == categories &&
        other.createdAt == createdAt &&
        other.day == day &&
        other.description == description &&
        other.id == id &&
        other.imageUrl == imageUrl &&
        other.title == title &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return author.hashCode ^
        categories.hashCode ^
        createdAt.hashCode ^
        day.hashCode ^
        description.hashCode ^
        id.hashCode ^
        imageUrl.hashCode ^
        title.hashCode ^
        updatedAt.hashCode;
  }
}
