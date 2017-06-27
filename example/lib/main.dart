import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map_tiles/map_tiles.dart';
import 'package:geo/geo.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MapController controller = new MapController()
    ..center = new LatLng(0, 0)
    ..zoom = 1;

  @override
  void initState() {
    super.initState();
    new Timer.periodic(const Duration(seconds: 5), (t) {
      if (controller.zoom++ == 12) {
        controller.zoom = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new TileLayer(
          imageMapType: new OpenStreetMapImageMapType(),
          controller: controller,
        ),
      ),
    );
  }
}
