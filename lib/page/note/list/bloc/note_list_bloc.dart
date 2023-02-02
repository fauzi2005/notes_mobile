import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../helper/db_helper.dart';
import '../../../../model/note_model.dart';
import 'note_list_event.dart';
import 'note_list_state.dart';

class NoteListBloc extends Bloc<NoteListEvent, NoteListState> {
  NoteListBloc() : super(NoteListInitial()) {
    on<NoteListLoaded>(noteListLoaded);
  }

  FutureOr<void> noteListLoaded(NoteListLoaded event, Emitter<NoteListState> emit) async {
    if(event.isLoading) {
      emit(NoteListLoading());
    }

    await Future.delayed(const Duration(milliseconds: 200));

    final ahai = await DBHelper.getAllNotes();

    List<NoteModel> noteModel = [];

    for(var e in ahai) {
      noteModel.add(
        NoteModel(
            notesId: e.notesId,
            notesTitle: e.notesTitle,
            notesBody: e.notesBody,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt
        )
      );
    }

    emit(NoteListSuccess(noteModel: noteModel));

    emit(NoteListFinished());
  }
}
