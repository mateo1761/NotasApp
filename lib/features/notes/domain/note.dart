class Note {
  final String id;         // el backend devuelve String(Date.now())
  final String title;
  final String content;
  final int updatedAt;     // epoch ms

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        updatedAt: (json['updatedAt'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt,
      };

  Note copyWith({String? title, String? content, int? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
