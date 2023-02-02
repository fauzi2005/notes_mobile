import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../helper/db_helper.dart';
import '../../../helper/preferences.dart';
import '../../../model/note_model.dart';
import '../../../util/flushbars.dart';
import '../form/note_form_page.dart';
import 'bloc/note_list_bloc.dart';
import 'bloc/note_list_event.dart';
import 'bloc/note_list_state.dart';

class NoteListPage extends StatefulWidget {
  final void Function()? changeTheme;
  bool isDark;
  String? flushbarNote;
  final bool initMethod;
  NoteListPage({Key? key, this.changeTheme, this.isDark = false, this.flushbarNote, this.initMethod = true})
      : super(key: key);

  @override
  State<NoteListPage> createState() => _HomeState();
}

class _HomeState extends State<NoteListPage> {

  List<NoteModel> noteModel = [];

  bool isLoading = true;

  List<bool> visiblePassword = [true, true, true];

  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if(widget.initMethod) {
      refresh(widget.initMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NoteListBloc, NoteListState>(
      listener: (context, state) {
        if(state is NoteListLoading) {
          setState(() {
            isLoading = true;
          });

          if(widget.flushbarNote == 'delete') {
            Flushbars.showSuccess("Note Deleted!").show(context);
          } else if(widget.flushbarNote == 'new') {
            Flushbars.showSuccess("New Note Added!").show(context);
          } else if(widget.flushbarNote == 'update') {
            Flushbars.showSuccess("Note Updated!").show(context);
          }

          setState(() {
            widget.flushbarNote = '';
          });
        } else if(state is NoteListSuccess) {
          setState(() {
            noteModel.clear();
            noteModel = state.noteModel;
            // noteModel.sort((b, a) => a.from.compareTo(b.from));
            noteModel.sort((b, a) => a.notesTitle.compareTo(b.notesTitle));

            // var e = groupBy(state.noteModel, (NoteModel list) => list.notesTitle);
          });
        } else if(state is NoteListFinished) {
          setState(() {
            isLoading = false;
          });
        }
      },
      child: Scaffold(
        drawer: drawer(),
        appBar: appBar(),
        body: body(),
        floatingActionButton: floatingActionButton(),
      ),
    );
  }

  Drawer drawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Notes List',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.dark_mode,
                  color: Colors.grey,
                ),
                // Text('Dark Mode'),
                Padding(
                  padding: const EdgeInsets.only(left: 20,right: 6),
                  child: Switch(
                    activeColor: Colors.blue,
                    value: widget.isDark,
                    onChanged: (v) {
                      setState(() {
                        widget.isDark = !widget.isDark;
                        widget.changeTheme!();
                      });
                    },
                  ),
                ),
                const Text("Dark Theme")
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.upload,
              color: Colors.grey,
            ),
            title: const Text('Import'),
            onTap: () async {
              await DBHelper.importDb().then((value) {
                if(value == 'failed') {
                  Flushbars.showFailure('Data is exists').show(context);
                } else {
                  setState(() {
                    refresh(true);
                  });
                  Flushbars.showSuccess('The data has been imported').show(context);
                }
              });
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.download,
              color: Colors.grey,
            ),
            title: const Text('Export'),
            onTap: () {
              DBHelper.exportDb();

              Flushbars.showSuccess('Export success').show(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.grey,
            ),
            title: const Text('Delete All'),
            onTap: () {
              confirmDeleteAll();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.password,
              color: Colors.grey,
            ),
            title: const Text('Change Password'),
            onTap: () {
              changePassword();
            },
          ),
        ],
      ),
    );
  }

  AppBar appBar() {
    Color? iconColor = Theme.of(context).brightness == Brightness.light ? Colors.black : null;
    return AppBar(
        title: const Text("Notes List"),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          /*PopupMenuButton(
            onSelected: (value) {
              if(value == 2) {
                confirmDeleteAll();
              }
              if(value == 3) {
                changePassword();
              }
            },
            itemBuilder: (context) {
              return <PopupMenuEntry>[
                PopupMenuItem(
                  onTap: () async {
                    await DBHelper.importDb().then((value) {
                      if(value == 'failed') {
                        Flushbars.showFailure('Data is exists').show(context);
                      } else {
                        setState(() {
                          refresh(true);
                        });
                        Flushbars.showSuccess('The data has been imported').show(context);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.upload, color: iconColor),
                      const SizedBox(width: 5),
                      const Text('Import')
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () async {
                    await DBHelper.exportDb();

                    Flushbars.showSuccess('Export success').show(context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.download, color: iconColor),
                      const SizedBox(width: 5),
                      const Text('Export')
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: iconColor),
                      const SizedBox(width: 5),
                      const Text('Delete All')
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 3,
                  child: Row(
                    children: [
                      Icon(Icons.password, color: iconColor),
                      const SizedBox(width: 5),
                      const Text('Change Password')
                    ],
                  ),
                ),
              ];
            },
            position: PopupMenuPosition.under,
          )*/
        ],
      );
  }

  Widget body() {
    if(isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      if(noteModel.isNotEmpty) {
        return RefreshIndicator(
          onRefresh: () async => refresh(true),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: MasonryGridView.builder(
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              itemCount: noteModel.length,
              gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              itemBuilder: (context, index) {
                NoteModel noteModelDetail = noteModel[index];
                String updatedAt = DateFormat("dd MMMM yyyy").format(DateTime.parse(noteModelDetail.updatedAt));
                if(updatedAt == DateFormat("dd MMMM yyyy").format(DateTime.now())) {
                  updatedAt = DateFormat("HH:mm").format(DateTime.parse(noteModelDetail.updatedAt));
                }

                return Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NoteFormPage(noteModel: noteModelDetail))).whenComplete(() => refresh(false));
                    },
                    borderRadius: BorderRadius.circular(15.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(noteModelDetail.notesTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const Divider(
                                  thickness: 1,
                                ),
                              ],
                            ),
                            subtitle: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 100),
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  Html(
                                    data: noteModelDetail.notesBody.toString(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 18, bottom: 8),
                                child: Text(
                                  updatedAt.toString(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        return RefreshIndicator(
          onRefresh: () async => refresh(true),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Text('Tidak ada Data'),
            ),
          ),
        );
      }

    }
  }

  Widget floatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Navigators.push(context, const NoteFormPage());
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NoteFormPage())).whenComplete(() => refresh(false));
      },
      tooltip: 'Add Note',
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.note_add),
    );
  }

  confirmDeleteAll() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Warning"),
          content: const Text("Would you like to delete all notes?"),
          actions: [
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Delete All"),
              onPressed: () {
                DBHelper.db.deleteAllNotes();

                Navigator.of(context).pop();

                refresh(true);

                Flushbars.showSuccess('Delete all data success').show(context);
              },
            ),
          ],
        );
      },
    );
  }

  changePassword() {
    newPasswordController.clear();
    oldPasswordController.clear();
    confirmPasswordController.clear();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width*0.8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Change password!', style: TextStyle(fontSize: 20)),
                          const Divider(color: Colors.grey, indent: 20, endIndent: 20),
                          const SizedBox(height: 10),
                          TextField(
                            controller: oldPasswordController,
                            obscureText: visiblePassword[0],
                            maxLength: 12,
                            decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30)
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                hintText: "Enter your old password",
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        visiblePassword[0] = !visiblePassword[0];
                                      });
                                    },
                                    icon: visiblePassword[0] ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                                )
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: newPasswordController,
                            obscureText: visiblePassword[1],
                            maxLength: 12,
                            decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30)
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                hintText: "Enter your new password",
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        visiblePassword[1] = !visiblePassword[1];
                                      });
                                    },
                                    icon: visiblePassword[1] ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                                )
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: visiblePassword[2],
                            maxLength: 12,
                            decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30)
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                hintText: "Confirm your new password",
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        visiblePassword[2] = !visiblePassword[2];
                                      });
                                    },
                                    icon: visiblePassword[2] ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                                )
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text("Change"),
                  onPressed: () {
                    if(oldPasswordController.text == Preferences.getInstance().getString(SharedPreferenceKey.PASSWORD)) {
                      if(newPasswordController.text.length < 4) {
                        Flushbars.showFailure('New password length must be at least 4 character').show(context);
                      } else {
                        if(newPasswordController.text != confirmPasswordController.text) {
                          Flushbars.showFailure('New password do not match').show(context);
                        } else {
                          Preferences.getInstance().setString(SharedPreferenceKey.PASSWORD, newPasswordController.text);
                          Flushbars.showSuccess('Change password success').show(context).whenComplete(() => Navigator.of(context).pop(context));
                        }
                      }
                    } else {
                      Flushbars.showFailure('Wrong password').show(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void refresh(bool isLoading) {
    context.read<NoteListBloc>().add(NoteListLoaded(isLoading: isLoading));
  }

}