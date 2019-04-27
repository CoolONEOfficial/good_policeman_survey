import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class WidgetTemplates {
  static Widget _buildNotification(
          BuildContext ctx, String text, Widget widget) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            widget,
            Container(height: 20),
            Text(
              text,
              style: Theme.of(ctx).textTheme.title,
            )
          ],
        ),
      );

  static Widget buildErrorText(String error) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          error ?? "",
          textAlign: TextAlign.left,
          style: TextStyle(color: Colors.red),
        ),
      );

  static Widget _buildIconNotification(
    BuildContext ctx,
    String text, [
    IconData icon,
  ]) =>
      _buildNotification(
        ctx,
        text,
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Icon(icon, size: 140),
        ),
      );

  static Widget buildLoadingNotification(BuildContext ctx) =>
      _buildNotification(
        ctx,
        "Загрузка...",
        CircularProgressIndicator(),
      );

  static Widget buildErrorNotification(BuildContext ctx, String error) =>
      _buildIconNotification(ctx, error, Icons.error);

  static Image buildLogo() => Image.asset(
        'assets/icons/icon.png',
        width: 200,
        height: 260,
      );

  static Widget buildFutureBuilder<T>(
    BuildContext ctx, {
    @required Future future,
    @required AsyncWidgetBuilder<T> builder,
    Widget loading,
    Widget error,
  }) =>
      FutureBuilder<T>(
          future: future,
          builder: (BuildContext ctx, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.active:
              case ConnectionState.waiting:
                return loading ?? WidgetTemplates.buildLoadingNotification(ctx);
                break;
              case ConnectionState.done:
                if (snapshot.hasError)
                  return error ??
                      WidgetTemplates.buildErrorNotification(
                          ctx, "${snapshot.error}" ?? "Unknown");
                return builder(ctx, snapshot);
            }
          });
}
