import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import '../../../helper/db_helper.dart';
import '../../../model/note_model.dart';
import '../../../util/flushbars.dart';

class NoteFormPage extends StatefulWidget {
  final NoteModel? noteModel;
  const NoteFormPage({Key? key, this.noteModel}) : super(key: key);

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  DateTime? createdAt;
  bool editable = false;
  TextEditingController titleController = TextEditingController();
  HtmlEditorController htmlController = HtmlEditorController();

  @override
  void initState() {
    super.initState();

    if(widget.noteModel != null) {
      editable = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noteModel != null) {
      setState(() {
        titleController.text = widget.noteModel!.notesTitle;
      });
    }

    return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          appBar: appBar(),
          body: body(),
          bottomNavigationBar: bottomNavigationbar(),
        )
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Text(editable ? widget.noteModel != null ? 'Detail Note' : 'Save Note' : 'Save Data'),
      backgroundColor: Theme.of(context).primaryColor,
      actions: [
        Visibility(
          visible: widget.noteModel != null,
          child: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              dialogDelete();
            },
          ),
        ),
        Visibility(
          visible: editable,
          child: IconButton(
            onPressed: () {
              setState(() {
                editable = false;
              });
            },
            icon: const Icon(Icons.edit),
          ),
        )
      ],
    );
  }

  Widget body() {
    if(editable) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.noteModel!.notesTitle,
              style:const TextStyle(fontSize: 28,fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 2),
            Expanded(
              child: ListView(
                children: [
                  Html(
                    data: widget.noteModel!.notesBody,
                  ),
                ],
              ),
            )
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  maxLength: 24,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                      hintText: 'Note Title...',
                      counterText: ''
                  ),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Divider(
                  thickness: 2,
                ),
              ],
            ),
            Flexible(
              child: HtmlEditor(
                controller: htmlController,
                htmlEditorOptions: HtmlEditorOptions(
                  hint: "Type you Text here",
                  initialText: widget.noteModel != null ? widget.noteModel!.notesBody : '',
                  darkMode: true,
                ),
                htmlToolbarOptions: const HtmlToolbarOptions(
                  toolbarType: ToolbarType.nativeExpandable,
                  toolbarPosition: ToolbarPosition.aboveEditor,
                  defaultToolbarButtons: [
                    StyleButtons(style: false),
                    FontSettingButtons(),
                    FontButtons(),
                    ColorButtons(),
                    ListButtons(),
                    ParagraphButtons(),
                    InsertButtons(audio: false, table: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget? bottomNavigationbar() {
    if(editable) {
      return null;
    }
    return SizedBox(
      height: kBottomNavigationBarHeight,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: const RoundedRectangleBorder()
        ),
        onPressed: () {
          saveNote();
        },
        icon: const Icon(Icons.save),
        label: const Text('Save Note'),
      ),
    );
  }

  dialogDelete() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure want to delete it?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () async {
                DBHelper.db.deleteNote(widget.noteModel!.notesId!);
                await popToFirst();
                Flushbars.showSuccess('Delete note success').show(context);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  saveNote() async {
    String htmlBody = await htmlController.getText();
    setState(() {
      String html = htmlBody;
      createdAt = DateTime.now();

      if (titleController.text.isEmpty) {
        Flushbars.showFailureNoTitle('Please fill the title').show(context);
      } else {
        if (widget.noteModel != null) {
          NoteModel note = NoteModel(
            notesId: widget.noteModel!.notesId,
            notesTitle: titleController.text,
            notesBody: html,
            createdAt: widget.noteModel!.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
          DBHelper.db.updateNote(note);
          popToFirst();
        } else {
          NoteModel note = NoteModel(
            notesId: DateTime.now().difference(DateTime(2023, 01, 01)).inMilliseconds,
            notesTitle: titleController.text,
            notesBody: html,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );
          DBHelper.db.addNewNote(note);
          popToFirst();
        }
      }
    });
  }

  Future<bool> onWillPop() async {
    if(editable) {
      return true;
    } else {
      var bodyHtml = await htmlController.getText();

      //jika menambah data baru dan title kosong
      if (widget.noteModel == null && titleController.text == "" &&
          titleController.text.isEmpty) {
        return true;
      }

      //jika mengubah data dan sama dengan data sebelumnya
      if (widget.noteModel != null &&
          titleController.text == widget.noteModel!.notesTitle &&
          bodyHtml == widget.noteModel!.notesBody) {
        return true;
      }

      return await dialogs() ?? false;
    }
  }

  popToFirst() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  dialogs() {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your notes are not saved'),
          content: const Text(
              "Your notes haven't been saved, are you sure you want to go back?"),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

}