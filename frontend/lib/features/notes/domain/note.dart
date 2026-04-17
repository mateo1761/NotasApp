class Note {
  final String id;
  final String title;
  final String content;
  final String? location;
  final int updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.location,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        location: json['location'] as String?,
        updatedAt: (json['updatedAt'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'location': location,
        'updatedAt': updatedAt,
      };

  Note copyWith({
    String? title,
    String? content,
    String? location,
    int? updatedAt,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        location: location ?? this.location,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
