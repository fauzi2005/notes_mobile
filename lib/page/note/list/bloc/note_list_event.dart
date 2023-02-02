abstract class NoteListEvent {}

class NoteListLoaded extends NoteListEvent {
  final bool isLoading;

  NoteListLoaded({
    required this.isLoading,
  });
}
