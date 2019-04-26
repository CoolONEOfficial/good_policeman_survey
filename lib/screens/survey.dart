import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:progress_hud/progress_hud.dart';

enum Area {
  None,
  Autozavodsk,
  Kanavinsk,
  Leninsk,
  Moscowsk,
  Nizhegorodsk,
  Prioksk,
  Sovetsk,
  Sormovsk,
}

final StreamController<Area> _onArea = StreamController<Area>.broadcast();

class SurveyModel {
  Area area = Area.None;
}

class SurveyScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final ProgressHUD _progress = ProgressHUD(
    loading: false,
    backgroundColor: Colors.black12,
    color: Colors.white,
    containerColor: Colors.blue,
    borderRadius: 5.0,
    text: 'Загрузка...',
  );
  final _model = SurveyModel();
  final _areas = [
    "Не указано",
    "Автозаводский",
    "Канавинский",
    "Ленинский",
    "Московский",
    "Нижегородский",
    "Приокский",
    "Советский",
    "Сормовский",
  ];

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      _progress.state.show();

      // TODO: send
    }
  }

  Widget _areaInput(
    BuildContext ctx,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
        child: Row(
          children: <Widget>[
            Text("Район:", style: Theme.of(ctx).textTheme.title),
            Container(width: 10),
            StreamBuilder(
              stream: _onArea.stream,
              builder: (ctx, ssArea) => Flexible(
                    child: DropdownButtonFormField(
                      validator: (value) =>
                          value == 0 ? "Выберите район" : null,
                      value: _model.area.index,
                      items: _areas
                          .map<DropdownMenuItem>((val) => DropdownMenuItem(
                                value: _areas.indexOf(val),
                                child: Text(val),
                              ))
                          .toList(),
                      onChanged: (areaId) {
                        _model.area = Area.values[areaId];
                        _onArea.add(_model.area);
                      },
                    ),
                  ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Добавление анкеты"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _validateAndSubmit(),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  _areaInput(ctx),
                ],
              ),
            ),
          ),
          _progress
        ],
      ),
    );
  }
}
