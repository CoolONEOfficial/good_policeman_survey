import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:good_policeman_survey/screens/auth.dart';
import 'package:good_policeman_survey/screens/survey.dart';
import 'package:good_policeman_survey/widget_templates.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WidgetTemplates.buildFutureBuilder(
      context,
      loading: Container(),
      error: Container(),
      future: FlutterUdid.consistentUdid,
      builder: (ctx, ssDuid) => WidgetTemplates.buildFutureBuilder(
            ctx,
        loading: Container(),
        error: Container(),
            future: dbRef.child("uids").once(),
            builder: (ctx, ssUids) {
              return MaterialApp(
                title: 'Приложение для опроса',
                initialRoute: '/',
                routes: {
                  '/': (ctx) =>
                      ssUids.data?.value?.contains(ssDuid.data) ?? false
                          ? SurveyScreen()
                          : AuthScreen(),
                  '/auth': (ctx) => AuthScreen(),
                  '/survey': (ctx) => SurveyScreen(),
                },
              );
            },
          ),
    );
  }
}

final storageRef = FirebaseStorage.instance.ref(),
    dbRef = FirebaseDatabase.instance.reference();
