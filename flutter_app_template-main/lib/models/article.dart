import '../core/typedefs.dart';

/// EXAMPLE MODEL — delete this once you have real domain models.
///
/// It exists so the template ships one complete vertical slice
/// (`api → service → repository → view model → view`) you can copy. Follow its
/// shape for your own models: immutable fields, an explicit `fromJson` with
/// defensive parsing, `toJson`, `copyWith`, and value equality.
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.body,
    this.authorId,
    this.publishedAt,
  });

  /// Parses defensively: a backend that changes `id` from int to string, or
  /// omits a field, must not crash the list. Anything genuinely unparseable
  /// throws and is mapped to `ParsingException` by the repository.
  factory Article.fromJson(Json json) => Article(
    id: json['id'].toString(),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    authorId: json['userId']?.toString(),
    publishedAt: switch (json['published_at']) {
      final String value => DateTime.tryParse(value),
      _ => null,
    },
  );

  final String id;
  final String title;
  final String body;
  final String? authorId;
  final DateTime? publishedAt;

  /// First line of the body, for list rows.
  String get excerpt {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length <= 120
        ? normalized
        : '${normalized.substring(0, 120).trimRight()}…';
  }

  Json toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'userId': authorId,
    'published_at': publishedAt?.toUtc().toIso8601String(),
  };

  Article copyWith({
    String? id,
    String? title,
    String? body,
    String? authorId,
    DateTime? publishedAt,
  }) => Article(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    authorId: authorId ?? this.authorId,
    publishedAt: publishedAt ?? this.publishedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Article &&
          other.id == id &&
          other.title == title &&
          other.body == body;

  @override
  int get hashCode => Object.hash(id, title, body);

  @override
  String toString() => 'Article(id: $id, title: $title)';
}
