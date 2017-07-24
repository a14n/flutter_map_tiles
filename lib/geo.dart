import 'dart:convert' show Codec, Converter;
import 'dart:math' as math;
import 'dart:math' show Point, Rectangle;

import 'package:geo/geo.dart';
import 'package:meta/meta.dart';

export 'package:geo/geo.dart';

class LatLngBounds {
  LatLngBounds(List<LatLng> latlngs) {
    assert(latlngs != null);
    assert(latlngs.isNotEmpty);
    latlngs.forEach(extendWithLatLng);
  }

  LatLng _southWest;
  LatLng get southWest => _southWest;

  LatLng _northEast;
  LatLng get northEast => _northEast;

  LatLng get center => new LatLng(
        (southWest.lat + northEast.lat) / 2,
        (southWest.lng + northEast.lng) / 2,
      );

  num get width => northEast.lng - southWest.lng;
  num get height => northEast.lat - southWest.lat;

  num get north => northEast.lat;
  num get east => northEast.lng;
  num get south => southWest.lat;
  num get west => southWest.lng;

  void extendWithLatLng(LatLng latlng) {
    assert(latlng != null);
    if (_southWest == null && _northEast == null) {
      _southWest = latlng;
      _northEast = latlng;
      return;
    }
    final sw = southWest;
    final ne = northEast;
    _southWest = new LatLng(
      math.min(sw.lat, latlng.lat),
      math.min(sw.lng, latlng.lng),
    );
    _northEast = new LatLng(
      math.max(ne.lat, latlng.lat),
      math.max(ne.lng, latlng.lng),
    );
  }

  void extendWithLatLngBounds(LatLngBounds bounds) {
    assert(bounds != null);
    extendWithLatLng(bounds.northEast);
    extendWithLatLng(bounds.southWest);
  }

  void pad(double bufferRatio) {
    assert(bufferRatio >= 0);
    final sw = southWest;
    final ne = northEast;
    final h = height;
    final w = width;
    _southWest = new LatLng(
      sw.lat - h * bufferRatio,
      sw.lng - w * bufferRatio,
    );
    _northEast = new LatLng(
      ne.lat + h * bufferRatio,
      ne.lng + w * bufferRatio,
    );
  }

  bool containsLatLng(LatLng latlng) {
    assert(latlng != null);
    return latlng.lat >= south &&
        latlng.lat <= north &&
        latlng.lng >= west &&
        latlng.lng <= east;
  }

  bool containsLatLngBounds(LatLngBounds bounds) {
    assert(bounds != null);
    return bounds.south >= south &&
        bounds.north <= north &&
        bounds.west >= west &&
        bounds.east <= east;
  }

  bool intersects(LatLngBounds bounds) {
    assert(bounds != null);
    return bounds.north >= south &&
        bounds.south <= north &&
        bounds.east >= west &&
        bounds.west <= east;
  }

  bool overlaps(LatLngBounds bounds) {
    assert(bounds != null);
    return bounds.north > south &&
        bounds.south < north &&
        bounds.east > west &&
        bounds.west < east;
  }

  String toBBoxString() => [west, south, east, north].join(',');
}

@immutable
abstract class CRS {
  const CRS();

  @protected
  Projection get projection;

  @protected
  PointTransformation get transformation;

  /// Returns the coordinates on the map of the [latlng] parameter.
  ///
  /// The `x` and `y` values are between 0 and 1.
  Point latLngToPoint(LatLng latlng) {
    final projectedPoint = projection.encode(latlng);
    return transformation.transform(projectedPoint);
  }

  LatLng pointToLatLng(Point point) {
    final untransformedPoint = transformation.untransform(point);
    return projection.decode(untransformedPoint);
  }

  Rectangle get projectedBounds {
    final b = projection.bounds;
    final min = transformation.transform(b.topLeft);
    final max = transformation.transform(b.bottomRight);
    return new Rectangle.fromPoints(min, max);
  }
}

class EPSG900913 extends CRS {
  const EPSG900913();

  @override
  Projection get projection => const SphericalMercator();

  @override
  PointTransformation get transformation {
    const scale = 0.5 / (math.PI * SphericalMercator.RADIUS);
    return const PointTransformation(scale, 0.5, -scale, 0.5);
  }
}

/// affine transformation : `(x, y)` into `(a*x + b, c*y + d)`
@immutable
class PointTransformation {
  const PointTransformation(
    this.a,
    this.b,
    this.c,
    this.d,
  );

  final num a, b, c, d;

  Point transform(Point point) => new Point(
        a * point.x + b,
        c * point.y + d,
      );

  Point untransform(Point point) => new Point(
        (point.x - b) / a,
        (point.y - d) / c,
      );
}

abstract class Projection extends Codec<LatLng, Point> {
  const Projection();

  Rectangle get bounds;
}

/// Spherical Mercator projection.
///
/// Some projected points:
/// - `new LatLng(-90, -180)` projectes to `Point(-20037508, -20037508)`
/// - `new LatLng(-90, 180)` projectes to `Point(-20037508, 20037508)`
/// - `new LatLng(90, -180)` projectes to `Point(20037508, -20037508)`
/// - `new LatLng(90, 180)` projectes to `Point(20037508, 20037508)`
/// - `new LatLng(0, 0)` projectes to `Point(0, 0)`
class SphericalMercator extends Projection {
  static const RADIUS = 6378137;
  static const MAX_LATITUDE = 85.0511287798;

  const SphericalMercator();

  @override
  final Converter<Point, LatLng> decoder = const _SphericalMercatorDecoder();

  @override
  final Converter<LatLng, Point> encoder = const _SphericalMercatorEncoder();

  Rectangle get bounds {
    const earthCircumference = RADIUS * math.PI;
    return const Rectangle(
      -earthCircumference / 2,
      -earthCircumference / 2,
      earthCircumference,
      earthCircumference,
    );
  }
}

class _SphericalMercatorEncoder extends Converter<LatLng, Point> {
  const _SphericalMercatorEncoder();

  @override
  Point convert(LatLng latlng) {
    const oneDegInRad = math.PI / 180;
    final lat = math.max(-SphericalMercator.MAX_LATITUDE,
        math.min(SphericalMercator.MAX_LATITUDE, latlng.lat));
    final sin = math.sin(lat * oneDegInRad);

    return new Point(
      SphericalMercator.RADIUS * latlng.lng * oneDegInRad,
      SphericalMercator.RADIUS * math.log((1 + sin) / (1 - sin)) / 2,
    );
  }
}

class _SphericalMercatorDecoder extends Converter<Point, LatLng> {
  const _SphericalMercatorDecoder();

  @override
  LatLng convert(Point point) {
    const oneRadInDeg = 180 / math.PI;
    return new LatLng(
      oneRadInDeg *
          (2 * math.atan(math.exp(point.y / SphericalMercator.RADIUS)) -
              math.PI / 2),
      point.x * oneRadInDeg / SphericalMercator.RADIUS,
    );
  }
}

main(List<String> args) {
  print(const SphericalMercator().bounds);
  print(const SphericalMercator().encode(new LatLng(-90, -180)));
  print(const SphericalMercator().encode(new LatLng(90, 180)));
  print(const SphericalMercator().encode(new LatLng(0, 0)));
  print(const SphericalMercator().encode(new LatLng(90, 0)));
  print(const SphericalMercator()
      .encode(new LatLng(SphericalMercator.MAX_LATITUDE, 0)));
  print(new EPSG900913().projectedBounds);
  print(new EPSG900913().latLngToPoint(new LatLng(48.6833, 6.2)));
}
