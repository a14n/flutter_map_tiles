import 'dart:math';
import 'package:flutter/widgets.dart';
import 'geo.dart';
import 'package:meta/meta.dart';

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
  void initState() {
    super.initState();
    widget.controller.addListener(_didUpdateMap);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_didUpdateMap);
  }

  void _didUpdateMap() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (context, size) {
        final tilesOnGlobe = 1 << widget.controller.zoom;

        final globeWidth = widget.imageMapType.tileSize.width * tilesOnGlobe;
        final globeHeight = widget.imageMapType.tileSize.height * tilesOnGlobe;

        Point scaleForZoom(Point p) => new Point(
              globeWidth * p.x,
              globeHeight * p.y,
            );

        final centerPoint = scaleForZoom(
            widget.imageMapType.crs.latLngToPoint(widget.controller.center));

        final screenCenter = new Point(
          size.maxWidth ~/ 2,
          size.maxHeight ~/ 2,
        );
        final screenOnGlobePosition = new Point(
          centerPoint.x - screenCenter.x,
          centerPoint.y - screenCenter.y,
        );
        final firstTileX =
            screenOnGlobePosition.x ~/ (globeWidth ~/ tilesOnGlobe);
        final firstTileY =
            screenOnGlobePosition.y ~/ (globeHeight ~/ tilesOnGlobe);

        final tiles = <Widget>[];
        for (var x = firstTileX; x < tilesOnGlobe; x++) {
          for (var y = firstTileY; y < tilesOnGlobe; y++) {
            final left = widget.imageMapType.tileSize.width * x -
                screenOnGlobePosition.x;
            if (left > size.maxWidth) break;
            final top = widget.imageMapType.tileSize.height * y -
                screenOnGlobePosition.y;
            if (top > size.maxHeight) break;
            tiles.add(new Positioned(
              left: left,
              width: widget.imageMapType.tileSize.width,
              top: top,
              height: widget.imageMapType.tileSize.height,
              child: new Image.network(widget.imageMapType.getTileUrl(
                x: x,
                y: y,
                zoom: widget.controller.zoom,
              )),
            ));
          }
        }
        return new Stack(
          children: tiles,
        );
      },
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
