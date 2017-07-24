import 'package:flutter/material.dart';
import 'package:flutter_map_tiles/geo.dart';
import 'package:flutter_map_tiles/map_tiles.dart';

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
      home: new MyHomePage(title: 'Demo of tiles map'),
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
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Stack(
        fit: StackFit.expand,
        children: [
          new GestureDetector(
            onDoubleTap: () {
              setState(() {
                controller.zoom = (controller.zoom + 1) % 20;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                controller.moveBy(-details.delta);
              });
            },
            child: new TileLayer(
              imageMapType: new OpenStreetMapImageMapType(),
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}
