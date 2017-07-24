import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'geo.dart';

typedef Widget TileBuilder(Point<int> coordinates);

class TileView extends StatelessWidget {
  TileView({
    @required this.globalSize,
    @required this.center,
    @required this.tileSize,
    @required this.tileBuilder,
  });

  final Size globalSize;
  final Size tileSize;
  final TileBuilder tileBuilder;
  final Offset center;

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (context, size) {
        final screenCenter = new Offset(
          size.maxWidth / 2,
          size.maxHeight / 2,
        );
        final centerCoordinates = new Point<int>(
          center.dx ~/ tileSize.width,
          center.dy ~/ tileSize.height,
        );

        final children = <Widget>[];
        void addTile(Point<int> p) {
          final zone = new Rect.fromLTWH(
            p.x * tileSize.width - center.dx + screenCenter.dx,
            p.y * tileSize.height - center.dy + screenCenter.dy,
            tileSize.width,
            tileSize.height,
          );
          if (zone.right >= 0 &&
              zone.bottom >= 0 &&
              zone.left <= size.maxWidth &&
              zone.top <= size.maxHeight) {
            children.add(new Positioned.fromRect(
              rect: zone,
              child: tileBuilder(p),
            ));
          }
        }

        addTile(centerCoordinates);

        int border = 1;
        int oldTilesCount;
        while (oldTilesCount != children.length) {
          oldTilesCount = children.length;

          addTile(new Point<int>(
            centerCoordinates.x - border,
            centerCoordinates.y,
          ));
          addTile(new Point<int>(
            centerCoordinates.x + border,
            centerCoordinates.y,
          ));
          addTile(new Point<int>(
            centerCoordinates.x,
            centerCoordinates.y - border,
          ));
          addTile(new Point<int>(
            centerCoordinates.x,
            centerCoordinates.y + border,
          ));
          for (var i = 1; i < border; i++) {
            addTile(new Point<int>(
              centerCoordinates.x - border,
              centerCoordinates.y - i,
            ));
            addTile(new Point<int>(
              centerCoordinates.x - border,
              centerCoordinates.y + i,
            ));
            addTile(new Point<int>(
              centerCoordinates.x + border,
              centerCoordinates.y - i,
            ));
            addTile(new Point<int>(
              centerCoordinates.x + border,
              centerCoordinates.y + i,
            ));
            addTile(new Point<int>(
              centerCoordinates.x - i,
              centerCoordinates.y - border,
            ));
            addTile(new Point<int>(
              centerCoordinates.x + i,
              centerCoordinates.y - border,
            ));
            addTile(new Point<int>(
              centerCoordinates.x - i,
              centerCoordinates.y + border,
            ));
            addTile(new Point<int>(
              centerCoordinates.x + i,
              centerCoordinates.y + border,
            ));
          }
          addTile(new Point<int>(
            centerCoordinates.x - border,
            centerCoordinates.y - border,
          ));
          addTile(new Point<int>(
            centerCoordinates.x + border,
            centerCoordinates.y - border,
          ));
          addTile(new Point<int>(
            centerCoordinates.x - border,
            centerCoordinates.y + border,
          ));
          addTile(new Point<int>(
            centerCoordinates.x + border,
            centerCoordinates.y + border,
          ));

          border++;
        }

        return new Stack(children: children);
      },
    );
  }
}

class TileLayer extends StatefulWidget {
  TileLayer({
    @required this.imageMapType,
    @required this.controller,
  });

  final ImageMapType imageMapType;
  final MapController controller;

  @override
  State<TileLayer> createState() => new TileLayerState();
}

class TileLayerState extends State<TileLayer> {
  @override
  Widget build(BuildContext context) {
    final tilesOnGlobe = 1 << widget.controller.zoom;

    final mapSize = new Size(
      widget.imageMapType.tileSize.width * tilesOnGlobe,
      widget.imageMapType.tileSize.height * tilesOnGlobe,
    );

    widget.controller.crs = widget.imageMapType.crs;
    widget.controller.mapSize = mapSize;

    Offset scaleForZoom(Point p) => new Offset(
          mapSize.width * p.x,
          mapSize.height * p.y,
        );

    return new TileView(
      center: scaleForZoom(
          widget.imageMapType.crs.latLngToPoint(widget.controller.center)),
      globalSize: mapSize,
      tileSize: widget.imageMapType.tileSize,
      tileBuilder: (coordinates) =>
          new Image.network(widget.imageMapType.getTileUrl(
            x: coordinates.x,
            y: coordinates.y,
            zoom: widget.controller.zoom,
          )),
    );
  }
}

class MapController extends ChangeNotifier {
  LatLng _center = new LatLng(0, 0);
  LatLng get center => _center;
  set center(LatLng center) {
    if (_center == center) return;
    _center = center;
    notifyListeners();
  }

  int _zoom = 0;
  int get zoom => _zoom;
  set zoom(int zoom) {
    if (_zoom == zoom) return;
    _zoom = zoom;
    notifyListeners();
  }

  Size mapSize;

  CRS crs;

  void moveBy(Offset delta) {
    final centerOffset = crs.latLngToPoint(center);
    center = crs.pointToLatLng(new Point(
      centerOffset.x + delta.dx / mapSize.width,
      centerOffset.y + delta.dy / mapSize.height,
    ));
  }
}

typedef String TileUrlBuilder({
  @required int x,
  @required int y,
  @required int zoom,
});

@immutable
class ImageMapType {
  const ImageMapType({
    @required this.crs,
    @required this.getTileUrl,
    @required this.tileSize,
    this.maxZoom,
    this.name,
  });
  final TileUrlBuilder getTileUrl;
  final Size tileSize;
  final int maxZoom;
  final String name;
  final CRS crs;
}

class OpenStreetMapImageMapType extends ImageMapType {
  OpenStreetMapImageMapType({
    String name,
  })
      : super(
          crs: const EPSG900913(),
          tileSize: const Size(256.0, 256.0),
          maxZoom: 18,
          name: name,
          getTileUrl: ({x, y, zoom}) {
            var tilesOnGlobe = 1 << zoom;
            x = x % tilesOnGlobe;
            if (x < 0) {
              x = tilesOnGlobe + x;
            }
            return 'http://tile.openstreetmap.org/$zoom/$x/$y.png';
          },
        );
}
