import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:good_policeman_survey/main.dart';
import 'package:good_policeman_survey/widget_templates.dart';
import 'package:progress_hud/progress_hud.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ProgressHUD _progress = ProgressHUD(
    loading: false,
    backgroundColor: Colors.black12,
    color: Colors.white,
    containerColor: Colors.blue,
    borderRadius: 5.0,
    text: 'Загрузка...',
  );

  TextEditingController keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext ctx) => Theme(
        data: ThemeData(
          canvasColor: Colors.blue,
        ),
        child: Scaffold(
          body: Builder(
            builder: (ctx) => SafeArea(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            WidgetTemplates.buildLogo(),
                            Container(
                              width: 320,
                              child: Card(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller: keyController,
                                          decoration: InputDecoration(
                                            hintText: "Ключ регистрации",
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: RaisedButton(
                                          child: Text("Вход"),
                                          onPressed: () async {
                                            _progress.state.show();

                                            var keys = (await dbRef
                                                        .child("keys")
                                                        .once())
                                                    .value ??
                                                [];

                                            final keyId = keys
                                                .indexOf(keyController.text);
                                            if (keyId != -1) {
                                              await dbRef
                                                  .child('uids')
                                                  .child(((await dbRef
                                                                  .child('uids')
                                                                  .once())
                                                              ?.value
                                                              ?.length ??
                                                          0)
                                                      .toString())
                                                  .set(duid);

                                              await dbRef.child("keys").update(
                                                  {keyId.toString(): null});

                                              Navigator.of(ctx)
                                                  .pushNamedAndRemoveUntil(
                                                '/survey',
                                                (Route<dynamic> route) => false,
                                              );
                                            } else {
                                              Scaffold.of(ctx)
                                                  .showSnackBar(SnackBar(
                                                content:
                                                    Text("Ключа нет в базе"),
                                              ));

                                              _progress.state.dismiss();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _progress
                    ],
                  ),
                ),
          ),
        ),
      );
}
