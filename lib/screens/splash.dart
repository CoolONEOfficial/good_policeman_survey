import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:good_policeman_survey/main.dart';
import 'package:good_policeman_survey/widget_templates.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    auth.currentUser().then((_user) {
      debugPrint("User uid: " + (_user != null ? _user?.uid : 'non defined'));
      user = _user;

      Navigator.of(context).pushNamedAndRemoveUntil(
        user != null ? '/survey' : '/auth',
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData(
          canvasColor: Colors.blue,
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.center,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  WidgetTemplates.buildLogo(),
                  CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                ]),
          ),
        ),
      );
}
