import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:good_policeman_survey/screens/auth.dart';
import 'package:good_policeman_survey/screens/splash.dart';
import 'package:good_policeman_survey/screens/survey.dart';
import 'package:good_policeman_survey/screens/total.dart';
import 'package:good_policeman_survey/widget_templates.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => MaterialApp(
        title: 'Приложение для опроса',
        initialRoute: '/',
        routes: {
          '/': (ctx) => SplashScreen(),
          '/auth': (ctx) => AuthScreen(),
          '/survey': (ctx) => SurveyScreen(),
          '/total': (ctx) => TotalScreen(),
        },
      );
}

String duid;

final storageRef = FirebaseStorage.instance.ref(),
    dbRef = FirebaseDatabase.instance.reference();
