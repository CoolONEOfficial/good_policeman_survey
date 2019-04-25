import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_udid/flutter_udid.dart';
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

    FlutterUdid.consistentUdid.then((_duid) async {
      duid = _duid;

      final uids = await dbRef.child("uids").once();

      Navigator.of(context).pushNamedAndRemoveUntil(
        uids?.value?.contains(duid) ?? false ? '/survey' : '/auth',
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
