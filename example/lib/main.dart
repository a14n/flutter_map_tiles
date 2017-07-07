import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map_tiles/map_tiles.dart';
import 'package:flutter_map_tiles/geo.dart';

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
  final MapController controller = new MapController()
    ..center = new LatLng(48.6833, 6.2)
    ..zoom = 3;

  @override
  void initState() {
    super.initState();
    //return;
    new Timer.periodic(const Duration(seconds: 2), (t) {
      if (controller.zoom++ == 15) {
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
