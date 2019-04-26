import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:good_policeman_survey/main.dart';
import 'package:progress_hud/progress_hud.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:geolocator/geolocator.dart';

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

final StreamController _onArea = StreamController<Area>.broadcast(),
    _onSelfie = StreamController<File>.broadcast();

class SurveyModel {
  final String areaName;
  final String selfieUrl;
  final Position position;

  const SurveyModel({
    this.areaName,
    this.selfieUrl,
    this.position,
  });

  toJson() => {
        "area": areaName,
        "selfie": selfieUrl,
        "position": {
          "lat": position.latitude,
          "lng": position.longitude,
        }
      };
}

class SurveyScreen extends StatelessWidget {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final ProgressHUD _progress = ProgressHUD(
    loading: false,
    backgroundColor: Colors.black12,
    color: Colors.white,
    containerColor: Colors.blue,
    borderRadius: 5.0,
    text: 'Загрузка...',
  );
  File _selfieImage;
  Area _area = Area.None;
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

  void _validateAndSubmit(BuildContext ctx) async {
    if (_validateAndSave()) {
      _progress.state.show();

      final url = await (await storageRef
              .child("survey/" + duid + '/' + randomAlphaNumeric(10))
              .putFile(_selfieImage)
              .onComplete)
          .ref
          .getDownloadURL();

      final position = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      if (position != null) {
        await dbRef.child("survey").push().set(
              SurveyModel(
                areaName: _areas[_area.index],
                selfieUrl: url,
                position: position,
              ).toJson(),
            );

        Navigator.of(ctx).pushNamedAndRemoveUntil(
          '/total',
          (Route<dynamic> route) => false,
        );
      } else {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text("Не получилось получить местоположение устройства"),
          ),
        );

        _progress.state.dismiss();
      }
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
                      value: _area?.index,
                      items: _areas
                          .map<DropdownMenuItem>((val) => DropdownMenuItem(
                                value: _areas.indexOf(val),
                                child: Text(val),
                              ))
                          .toList(),
                      onChanged: (areaId) {
                        _area = Area.values[areaId];
                        _onArea.add(_area);
                      },
                    ),
                  ),
            ),
          ],
        ),
      );

  Widget _selfieInput(
    BuildContext ctx,
  ) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
          child: StreamBuilder(
              stream: _onSelfie.stream,
              builder: (ctx, _) => CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        _selfieImage != null ? Colors.transparent : Colors.blue,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: _selfieImage != null
                          ? [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _selfieImage = null;
                                  _onSelfie.add(_selfieImage);
                                },
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () async {
                                  _selfieImage = await ImagePicker.pickImage(
                                      source: ImageSource.camera);
                                  _onSelfie.add(_selfieImage);
                                },
                              ),
                            ]
                          : [
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  size: 30,
                                ),
                                onPressed: () async {
                                  _selfieImage = await ImagePicker.pickImage(
                                      source: ImageSource.camera);
                                  _onSelfie.add(_selfieImage);
                                },
                              ),
                              Text(
                                "Добавить\nселфи",
                                textAlign: TextAlign.center,
                              )
                            ],
                    ),
                    backgroundImage: _selfieImage != null
                        ? FileImage(
                            _selfieImage,
                          )
                        : null,
                  )),
        ),
      );

  @override
  Widget build(BuildContext ctx) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Добавление анкеты"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _validateAndSubmit(ctx),
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  _areaInput(ctx),
                  _selfieInput(ctx),
                ],
              ),
            ),
            _progress
          ],
        ),
      );
}
