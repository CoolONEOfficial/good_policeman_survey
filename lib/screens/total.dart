import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:good_policeman_survey/screens/survey.dart';

enum SurveyResult {
  Uploaded,
  Cached,
}

final _resultNames = [
  "Анкета успешно отправлена",
  "Анкета успешно сохранена в кэш"
];

class TotalScreen extends StatelessWidget {
  final SurveyResult surveyResult;

  const TotalScreen(this.surveyResult, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext ctx) => Theme(
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
                  Center(
                    child: Container(
                      width: 350,
                      child: Column(
                        children: <Widget>[
                          Text(
                            _resultNames[surveyResult.index],
                            style: Theme.of(ctx).textTheme.display4.merge(
                                TextStyle(fontSize: 70, color: Colors.white)),
                          ),
                        ]..addAll(
                            surveyResult == SurveyResult.Cached
                                ? [
                                    Container(height: 20),
                                    SingleChildScrollView(
                                      child: Text(
                                        "Все закешированные анкеты (${cachedSurveys.length}) автоматически отправятся в базу данных при подключении к интернету",
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .display4
                                            .merge(TextStyle(
                                                fontSize: 30,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ]
                                : [],
                          ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    onPressed: () {
                      Navigator.of(ctx).pushNamedAndRemoveUntil(
                        '/survey',
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Icon(Icons.refresh),
                  ),
                ]),
          ),
        ),
      );
}
