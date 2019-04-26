import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:device_info/device_info.dart';
import 'package:good_policeman_survey/main.dart';
import 'package:good_policeman_survey/widget_templates.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<String> _getDuid() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  @override
  void initState() {
    super.initState();

    _getDuid().then((_duid) async {
      debugPrint("Udid: " + _duid);
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
