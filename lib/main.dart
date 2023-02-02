import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_mobile/helper/preferences.dart';
import 'page/note/list/bloc/note_list_bloc.dart';
import 'page/note/list/note_list_page.dart';
import 'util/flushbars.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Preferences.getInstance().init();

  runApp(
      EasyLocalization(
          supportedLocales: const [
            Locale('id')
          ],
          path: 'assets/translation',
          fallbackLocale: const Locale('id'),
          saveLocale: true,
          startLocale: const Locale('id'),
          child: const MyApp()
      )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isDark = false;
  String passPref = '';
  final ThemeData _light = ThemeData.light().copyWith(primaryColor: const Color.fromARGB(255, 214, 135, 189));
  final ThemeData _dark = ThemeData.dark().copyWith(primaryColor: Colors.blueGrey);

  bool isPassPref = false;
  bool isPassPrefValid = false;
  bool visiblePassword = false;
  bool visibleConfirmPassword = false;

  void changeTheme() async {
    setState(() {
      _isDark = !_isDark;
      Preferences.getInstance().setBool(SharedPreferenceKey.DARKMODE, _isDark);
    });
  }

  void getPref() async {
    setState(() {
      _isDark = Preferences.getInstance().getBool(SharedPreferenceKey.DARKMODE) ?? false;
    });
  }

  void setPrefPass(String value) async {
    setState(() {
      Preferences.getInstance().setString(SharedPreferenceKey.PASSWORD, value);
      isPassPref = true;
      isPassPrefValid = true;
    });
  }

  Future<String> getStringValuesSF() async {
    passPref = Preferences.getInstance().getString(SharedPreferenceKey.PASSWORD)!;
    return passPref;
  }

  Future<bool> checkpass() async {
    isPassPref = Preferences.getInstance().contain(SharedPreferenceKey.PASSWORD);
    if(isPassPref) {
      getStringValuesSF();
    }
    return isPassPref;
  }

  @override
  void initState() {
    super.initState();
    getPref();
    checkpass();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NoteListBloc()),
      ],
      child: MaterialApp(
        title: 'Notes',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        darkTheme: _dark,
        theme: _light,
        themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child ?? Container()
          );
        },
        home: pf(),
      ),
    );
  }

  Widget pf() {
    if(isPassPref) {
      if(isPassPrefValid) {
        return NoteListPage(changeTheme: changeTheme, isDark: _isDark);
      } else {
        return Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Stack(
                  children: [
                    NoteListPage(changeTheme: changeTheme, isDark: _isDark, initMethod: false),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width*0.8,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Enter your password!', style: TextStyle(fontSize: 20)),
                                    const Divider(color: Colors.grey, indent: 20, endIndent: 20),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: passwordController,
                                      obscureText: !visiblePassword,
                                      maxLength: 12,
                                      decoration: InputDecoration(
                                          counterText: '',
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30)
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          hintText: "Enter your password",
                                          suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  visiblePassword = !visiblePassword;
                                                });
                                              },
                                              icon: !visiblePassword ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                                          )
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                        onPressed: () {
                                          if(passwordController.text.contains(passPref)) {
                                            setState(() {
                                              isPassPrefValid = true;
                                            });
                                          } else {
                                            Flushbars.showFailure('Wrong password').show(context);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            fixedSize: Size(MediaQuery.of(context).size.width, 45)
                                        ),
                                        child: const Text('SUBMIT')
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
              ),
            );
          },
        );
      }
    } else {
      return Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Stack(
                children: [
                  NoteListPage(changeTheme: changeTheme, isDark: _isDark, initMethod: false),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width*0.8,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Set up your password first!', style: TextStyle(fontSize: 20)),
                                  const Divider(color: Colors.grey, indent: 20, endIndent: 20),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: !visiblePassword,
                                    keyboardType: TextInputType.visiblePassword,
                                    maxLength: 12,
                                    decoration: InputDecoration(
                                        counterText: '',
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30)
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        hintText: "Set up your password",
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                visiblePassword = !visiblePassword;
                                              });
                                            },
                                            icon: !visiblePassword ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                                        )
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: confirmPasswordController,
                                    obscureText: !visibleConfirmPassword,
                                    keyboardType: TextInputType.visiblePassword,
                                    maxLength: 12,
                                    decoration: InputDecoration(
                                        counterText: '',
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30)
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        hintText: "Confirm your password",
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                visibleConfirmPassword = !visibleConfirmPassword;
                                              });
                                            },
                                            icon: !visibleConfirmPassword ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                                        )
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                      onPressed: () {
                                        if(passwordController.text.length < 4){
                                          Flushbars.showFailure('Password must have at least 4 characters').show(context);
                                        } else {
                                          if(passwordController.text != confirmPasswordController.text) {
                                            Flushbars.showFailure('Password confirmation does not match').show(context);
                                          } else {
                                            setPrefPass(passwordController.text);
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                          fixedSize: Size(MediaQuery.of(context).size.width, 45)
                                      ),
                                      child: const Text('SUBMIT')
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
            ),
          );
        },
      );
    }

  }
}