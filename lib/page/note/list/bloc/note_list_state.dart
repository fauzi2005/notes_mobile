import '../../../../model/note_model.dart';

abstract class NoteListState {}

class NoteListInitial extends NoteListState {}

class NoteListLoading extends NoteListState {}

class NoteListSuccess extends NoteListState {
  final List<NoteModel> noteModel;

  NoteListSuccess({
    required this.noteModel,
  });
}

class NoteListFailed extends NoteListState {}

class NoteListFinished extends NoteListState {}
