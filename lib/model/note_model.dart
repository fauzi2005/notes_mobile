import 'dart:convert';

class NoteModel {
  final int? notesId;
  final String notesTitle;
  final String? notesBody;
  final String createdAt;
  final String updatedAt;

  NoteModel({
    this.notesId,
    required this.notesTitle,
    this.notesBody,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'notes_id': notesId,
      'notes_title': notesTitle,
      'notes_body': notesBody,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static NoteModel fromMap(Map<String, dynamic> map) {
    return NoteModel(
      notesId: map['notes_id'],
      notesTitle: map['notes_title'],
      notesBody: map['notes_body'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at']
    );
  }

  static NoteModel fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return fromMap(map);
  }

}