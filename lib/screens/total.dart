import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TotalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Theme(
        data: ThemeData(
          canvasColor: Colors.blue,
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text(
                      "Анкета успешно отправлена",
                      style: Theme.of(ctx).textTheme.display4.merge(TextStyle(fontSize: 70, color: Colors.white)),
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
        ),
      );
}
