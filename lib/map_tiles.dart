import 'package:flutter/widgets.dart';
import 'package:geo/geo.dart';
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
        final tiles = <Widget>[];
        for (var x = 0; x < tilesOnGlobe; x++) {
          for (var y = 0; y < tilesOnGlobe; y++) {
            final left = widget.imageMapType.tileSize.width * x;
            if (left > size.maxWidth) break;
            final top = widget.imageMapType.tileSize.height * y;
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
    @required this.getTileUrl,
    @required this.tileSize,
    this.maxZoom,
    this.name,
  });
  final TileUrlBuilder getTileUrl;
  final Size tileSize;
  final int maxZoom;
  final String name;
}

class OpenStreetMapImageMapType extends ImageMapType {
  OpenStreetMapImageMapType({
    String name,
  })
      : super(
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
