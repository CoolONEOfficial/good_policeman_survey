import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:badges/badges.dart';
import 'package:good_policeman_survey/main.dart';
import 'package:good_policeman_survey/screens/total.dart';
import 'package:good_policeman_survey/widget_templates.dart';
import 'package:path/path.dart';
import 'package:progress_hud/progress_hud.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity/connectivity.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_tagging/flutter_tagging.dart';

enum Gender {
  Unknown,
  Male,
  Female,
}

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

final _areaNames = [
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

StreamSubscription internetSub;

void _addCachedSurvey([
  SurveyModel model,
]) {
  if (model != null) cachedSurveys.add(model);
  if (internetSub == null) {
    internetSub = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result != ConnectivityResult.none) {
        Fluttertoast.showToast(
          backgroundColor: Colors.blue,
          msg: "Начата загрузка анкет из кэша в базу",
        );
        final len = cachedSurveys.length;
        do {
          var model = cachedSurveys.last;
          await dbRef.child("survey").push().set(await model.toDb());
          cachedSurveys.removeLast();
          _onCache.add(null);

          Fluttertoast.cancel();
          Fluttertoast.showToast(
            backgroundColor: Colors.blue,
            msg: "(${len - cachedSurveys.length}/$len)",
          );
        } while (cachedSurveys.isNotEmpty);

        final localLen = localStorage.getItem('len');
        if (localLen != null) {
          for (var i = 0; i < localLen; i++) {
            localStorage.deleteItem(i.toString());
          }
          localStorage.deleteItem('len');
        }

        internetSub.cancel().then((_) {
          internetSub = null;
        });
      }
    });
  }
}

List<SurveyModel> cachedSurveys = [];

final _ageNames = [
  'Не указано',
  '<18',
  '18-24',
  '25-36',
  '37-50',
  '51-75',
  '>75'
];

final _genderNames = ['male', 'anonym', 'female'];

final _genders = [Gender.Male, Gender.Unknown, Gender.Female];

final StreamController _onArea = StreamController<Area>.broadcast(),
    _onSelfie = StreamController<File>.broadcast(),
    _onGender = StreamController<Gender>.broadcast(),
    _onAge = StreamController<int>.broadcast(),
    _onAdContact = StreamController<bool>.broadcast(),
    _onCache = StreamController.broadcast();

class SurveyModel {
  final String areaName;
  final File selfieFile;
  final Position position;
  final Gender gender;
  final String age;
  final bool adContact;
  final List problems;

  factory SurveyModel.fromCache(Map<String, dynamic> json) {
    final model = SurveyModel(
        areaName: json["area"],
        position: Position(
          latitude: json["position"]["lat"],
          longitude: json["position"]["lng"],
        ),
        gender: Gender.values[_genderNames.indexOf(json["gender"])],
        age: json["age"],
        adContact: json["adContact"],
        problems: json["problems"],
        selfieFile: File(json["selfieFile"]));

    debugPrint("Cache json model: " + jsonEncode(json));
    if (model.selfieFile != null)
      model.selfieFile.exists().then(
            (e) => debugPrint("Selfie file exists: " +
                e.toString() +
                " on " +
                model.selfieFile.path),
          );

    return model;
  }

  const SurveyModel({
    this.areaName,
    this.selfieFile,
    this.position,
    this.gender,
    this.age,
    this.adContact,
    this.problems,
  });

  _jsonBase() => {
        "area": areaName,
        "position": {
          "lat": position.latitude,
          "lng": position.longitude,
        },
        "gender": _genderNames[gender.index],
        "age": age,
        "adContact": adContact,
        "problems": problems,
      };

  Map<String, dynamic> toCache() => {
        "selfieFile": selfieFile?.path,
      }..addAll(_jsonBase());

  Future<Map<String, dynamic>> toDb() async => {
        "selfieUrl": selfieFile != null
            ? await (await storageRef
                    .child("survey/" + user.uid + '/' + basename(selfieFile.path))
                    .putFile(selfieFile)
                    .onComplete)
                .ref
                .getDownloadURL()
            : null,
      }..addAll(_jsonBase());
}

class SurveyScreen extends StatefulWidget {
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>(),
      _formKey = GlobalKey<FormState>();

  final ProgressHUD _progress = ProgressHUD(
    loading: false,
    backgroundColor: Colors.black12,
    color: Colors.white,
    containerColor: Colors.blue,
    borderRadius: 5.0,
    text: 'Загрузка...',
  );

  File _selfieFile;

  set selfieFile(val) {
    _selfieFile = val;
    _onSelfie.add(_selfieFile);
  }

  Area _area = Area.None;
  Gender _gender = Gender.Unknown;
  int _ageId = 0;
  bool _adContact = false;
  List _problems = [];
  String _problemsError, _genderError, _ageError;

  @override
  void initState() {
    super.initState();

    if (cachedSurveys.isEmpty)
      localStorage.ready.then((ready) {
        if (ready) {
          var len = localStorage.getItem('len') ?? 0;
          for (var i = 0; i < len; i++) {
            cachedSurveys.add(SurveyModel.fromCache(
              localStorage.getItem(i.toString()),
            ));
          }
          if (len > 0) _addCachedSurvey();
          _onCache.add(null);
        } else
          debugPrint("ERororor local storage not readyy!");
      });
  }

  void _validateAndSubmit(BuildContext ctx) async {
    bool valid = true;

    if (_ageId == 0) {
      valid = false;

      setState(() {
        _ageError = "Выберите возраст";
      });
    }

    if (_problems.isEmpty) {
      valid = false;

      setState(() {
        _problemsError = "Добавьте проблемы";
      });
    }

    if (_gender == Gender.Unknown) {
      valid = false;

      setState(() {
        _genderError = "Выберите пол";
      });
    }

    final form = _formKey.currentState;
    if (!form.validate()) {
      valid = false;
    }

    if (valid) {
      form.save();
      _progress.state.show();

      await _submit(ctx);

      if (_progress.state.mounted) _progress.state.dismiss();
    }
  }

  _submit(BuildContext ctx) async {
    final position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    String errorMessage;

    if (position != null) {
      final model = SurveyModel(
        areaName: _areaNames[_area.index],
        selfieFile: _selfieFile,
        position: position,
        gender: _gender,
        adContact: _adContact,
        age: _ageNames[_ageId],
        problems: _problems.map((problem) => problem["name"]).toList(),
      );

      SurveyResult sRes;

      if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
        if (await localStorage.ready) {
          _addCachedSurvey(model);
          localStorage
            ..setItem('len', cachedSurveys.length)
            ..setItem((cachedSurveys.length - 1).toString(), model.toCache());
          _onCache.add(null);

          sRes = SurveyResult.Cached;
        } else
          errorMessage = "Не удалось получить доступ к локальному хранилищу";
      } else {
        await dbRef.child("survey").push().set(await model.toDb());

        sRes = SurveyResult.Uploaded;
      }

      if (errorMessage == null) {
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => TotalScreen(sRes)),
          (Route<dynamic> route) => false,
        );
      }
    } else
      errorMessage = "Не получилось получить местоположение устройства";

    if (errorMessage != null)
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
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
                      items: _areaNames
                          .map<DropdownMenuItem>((val) => DropdownMenuItem(
                                value: _areaNames.indexOf(val),
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
          padding: const EdgeInsets.fromLTRB(15.0, 45.0, 15.0, 0.0),
          child: StreamBuilder(
              stream: _onSelfie.stream,
              builder: (ctx, _) => CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        _selfieFile != null ? Colors.transparent : Colors.blue,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: _selfieFile != null
                          ? [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => selfieFile = null,
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () async => selfieFile =
                                    await ImagePicker.pickImage(
                                        source: ImageSource.camera),
                              ),
                            ]
                          : [
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  size: 30,
                                ),
                                onPressed: () async => selfieFile =
                                    await ImagePicker.pickImage(
                                        source: ImageSource.camera),
                              ),
                              Text(
                                "Добавить\nселфи",
                                textAlign: TextAlign.center,
                              )
                            ],
                    ),
                    backgroundImage: _selfieFile != null
                        ? FileImage(
                            _selfieFile,
                          )
                        : null,
                  )),
        ),
      );

  Widget _genderInput(
    BuildContext ctx,
  ) =>
      Center(
        child: Column(
          children: <Widget>[
            StreamBuilder(
              stream: _onGender.stream,
              builder: (ctx, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: List.generate(
                      3,
                      (i) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                                15.0, 15.0, 15.0, 0.0),
                            child: GestureDetector(
                              onTap: () {
                                _genderError = null;
                                _gender = _genders[i];
                                _onGender.add(_gender);
                              },
                              child: Container(
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: AssetImage('assets/icons/' +
                                                _genderNames[i] +
                                                '.png'),
                                          )),
                                      foregroundDecoration:
                                          _gender == _genders[i]
                                              ? BoxDecoration()
                                              : BoxDecoration(
                                                  color: Colors.black,
                                                  shape: BoxShape.circle,
                                                  backgroundBlendMode:
                                                      BlendMode.saturation,
                                                ),
                                    ),
                                    Container(height: 10),
                                    Text(
                                      ["М", "Не указано", "Ж"][i],
                                      style: Theme.of(ctx).textTheme.title,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
            ),
            WidgetTemplates.buildErrorText(_genderError),
          ],
        ),
      );

  Widget _ageInput(
    BuildContext ctx,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
        child: Row(
          children: <Widget>[
            Text("Возраст:", style: Theme.of(ctx).textTheme.title),
            Container(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StreamBuilder(
                    stream: _onAge.stream,
                    builder: (ctx, _) => Slider(
                          onChanged: (value) {
                            _ageError = null;
                            _ageId = value.toInt();
                            debugPrint("age: " + _ageNames[_ageId]);
                            _onAge.add(_ageId);
                          },
                          divisions: _ageNames.length - 1,
                          label: _ageNames[_ageId],
                          value: _ageId.toDouble(),
                          min: 0,
                          max: (_ageNames.length - 1).toDouble(),
                        ),
                  ),
                  WidgetTemplates.buildErrorText(_ageError),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _adContactInput(
    BuildContext ctx,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
        child: StreamBuilder(
            stream: _onAdContact.stream,
            builder: (ctx, _) {
              return CheckboxListTile(
                value: _adContact,
                onChanged: (value) {
                  _adContact = value;
                  _onAdContact.add(_adContact);
                },
                title: Text('Готов контактировать с администрацией'),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
      );

  Widget _buildAddButton() => Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          color: Colors.grey.withOpacity(0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.add,
              color: Colors.white,
              size: 15.0,
            ),
            Text(
              "Добавить проблему",
              style: TextStyle(color: Colors.white, fontSize: 14.0),
            ),
          ],
        ),
      );

  Widget _problemsInput(BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FlutterTagging(
              textFieldDecoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Дороги, долгострой...",
                  labelText: "Введите проблемы"),
              addButtonWidget: _buildAddButton(),
              deleteIcon: Icon(Icons.cancel, color: Colors.white),
              suggestionsCallback: (query) {
                final sugg = _suggestions
                    .map((name) =>
                        {'name': name, 'value': _suggestions.indexOf(name) + 1})
                    .where((tag) => tag['name'].toLowerCase().contains(query))
                    .toList();
                if (query.isNotEmpty) sugg.add({'name': query, 'value': 0});
                return sugg;
              },
              onChanged: (result) {
                debugPrint("Problems: " + result.toString());
                setState(() {
                  _problemsError = null;
                  _problems = result;
                });
              },
            ),
            WidgetTemplates.buildErrorText(_problemsError),
          ],
        ),
      );

  @override
  Widget build(
    BuildContext ctx,
  ) =>
      Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Добавление анкеты"),
          actions: <Widget>[
            StreamBuilder(
                stream: _onCache.stream,
                builder: (ctx, _) => BadgeIconButton(
                      itemCount: cachedSurveys.length,
                      icon: Icon(Icons.send),
                      onPressed: () => _validateAndSubmit(ctx),
                    )),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  _genderInput(ctx),
                  _ageInput(ctx),
                  _areaInput(ctx),
                  _problemsInput(ctx),
                  _adContactInput(ctx),
                  _selfieInput(ctx),
                ],
              ),
            ),
            _progress
          ],
        ),
      );
}

final List _suggestions = [
  "Дороги",
  "Долгострой",
  "Мусор",
  "Экология",
  "Реклама",
  "Пробки",
];
