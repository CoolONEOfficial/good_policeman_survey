import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:good_policeman_survey/widget_templates.dart';

class TotalScreen extends StatelessWidget {
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
                  Text(
                    "Анкета успешно отправлена",
                    style: Theme.of(ctx).textTheme.title,
                  ),
                  FloatingActionButton(
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
