import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:good_policeman_survey/main.dart';
import 'package:progress_hud/progress_hud.dart';
import 'package:flutter_udid/flutter_udid.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  ProgressHUD _progressHUD = ProgressHUD(
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
  Widget build(BuildContext ctx) => Scaffold(
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
                          Image.asset(
                            'assets/icons/icon.png',
                            width: 200,
                            height: 260,
                          ),
                          Container(
                            width: 300,
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
                                      _progressHUD.state.show();

                                      var keys =
                                          (await dbRef.child("keys").once())
                                                  .value ??
                                              [];

                                      if (keys.contains(keyController.text)) {
                                        Navigator.of(ctx)
                                            .pushNamedAndRemoveUntil(
                                          '/survey',
                                          (Route<dynamic> route) => false,
                                        );

                                        dbRef
                                            .child('uids')
                                            .child(((await dbRef
                                                    .child('uids')
                                                    .once())
                                                ?.value
                                                ?.length ?? 0).toString())
                                            .set(await FlutterUdid
                                                .consistentUdid);
                                      } else {
                                        Scaffold.of(ctx).showSnackBar(SnackBar(
                                          content: Text("Ключа нет в базе"),
                                        ));
                                      }

                                      _progressHUD.state.dismiss();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _progressHUD
                  ],
                ),
              ),
        ),
      );
}
