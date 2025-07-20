import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abusina Map',
      home: MapScreen(),
    );
  }
}

enum MapStyle {
  osm,
  satellite,
  cartoLight,
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  List<Polygon> _polygons = [];
  List<Polygon> _gehoelzPolygone = [];
  List<Polygon> _wegeLinien = [];
  List<Marker> _gelaendeMarker = [];

  bool _showPolygons = true;
  bool _showGehoelz = true;
  bool _showWege = true;
  bool _showGelaende = true;

  MapStyle _mapStyle = MapStyle.osm;

  @override
  void initState() {
    super.initState();
    loadGeoJson();
    loadWeitereLayer();
  }

  Future<void> loadGeoJson() async {
    final data = await rootBundle.loadString('assets/mauer.geojson');
    final geo = json.decode(data);
    List<Polygon> polygons = [];

    double? minLat, maxLat, minLng, maxLng;

    for (var feature in geo['features']) {
      if (feature['geometry']['type'] == 'Polygon') {
        final coords = feature['geometry']['coordinates'][0];
        final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

        for (var p in points) {
          minLat = (minLat == null || p.latitude < minLat) ? p.latitude : minLat;
          maxLat = (maxLat == null || p.latitude > maxLat) ? p.latitude : maxLat;
          minLng = (minLng == null || p.longitude < minLng) ? p.longitude : minLng;
          maxLng = (maxLng == null || p.longitude > maxLng) ? p.longitude : maxLng;
        }

        polygons.add(Polygon(
          points: points,
          color: Colors.black,
          borderColor: Colors.black,
          borderStrokeWidth: 2,
        ));
      }
    }

    setState(() {
      _polygons = polygons;
    });

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      await Future.delayed(Duration(milliseconds: 300));
      _mapController.move(center, 17.8);
    }
  }

  Future<void> loadWeitereLayer() async {
    final gehoelzData = await rootBundle.loadString('assets/gehoelz.geojson');
    final gehoelzJson = json.decode(gehoelzData);

    for (var feature in gehoelzJson['features']) {
      if (feature['geometry']['type'] == 'Polygon') {
        final coords = feature['geometry']['coordinates'][0];
        final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

        _gehoelzPolygone.add(Polygon(
          points: points,
          color: Colors.green,
          borderColor: Colors.green,
          borderStrokeWidth: 1,
          isFilled: true,
        ));
      }
    }

    final wegData = await rootBundle.loadString('assets/weg.geojson');
    final wegJson = json.decode(wegData);

    for (var feature in wegJson['features']) {
      if (feature['geometry']['type'] == 'Polygon') {
        final coords = feature['geometry']['coordinates'][0];
        final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

        _wegeLinien.add(Polygon(
          points: points,
          color: Colors.brown,
          borderColor: Colors.brown,
          borderStrokeWidth: 2,
          isFilled: true,
        ));
      }
    }

    final gelaendeData = await rootBundle.loadString('assets/Gelendepunkt.geojson');
    final gelaendeJson = json.decode(gelaendeData);

    for (var feature in gelaendeJson['features']) {
      if (feature['geometry']['type'] == 'Point') {
        final coord = feature['geometry']['coordinates'];
        final point = LatLng(coord[1], coord[0]);

        _gelaendeMarker.add(Marker(
          width: 30,
          height: 30,
          point: point,
          child: Icon(Icons.location_on, color: Colors.blue, size: 20),
        ));
      }
    }

    setState(() {});
  }

  String getTileUrl() {
    switch (_mapStyle) {
      case MapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyle.cartoLight:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case MapStyle.osm:
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> getSubdomains() {
    return _mapStyle == MapStyle.cartoLight ? ['a', 'b', 'c', 'd'] : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kastell Abusina")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: LatLng(48.823, 11.790),
          zoom: 17.0,
        ),
        children: [
          TileLayer(
            urlTemplate: getTileUrl(),
            subdomains: getSubdomains(),
            userAgentPackageName: 'de.meinprojekt.abusina',
          ),
          if (_showPolygons) PolygonLayer(polygons: _polygons),
          if (_showGehoelz) PolygonLayer(polygons: _gehoelzPolygone),
          if (_showWege) PolygonLayer(polygons: _wegeLinien),
          if (_showGelaende) MarkerLayer(markers: _gelaendeMarker),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'mauer',
            onPressed: () => setState(() => _showPolygons = !_showPolygons),
            tooltip: 'Mauer Layer',
            child: Icon(_showPolygons ? Icons.visibility : Icons.visibility_off),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'gehoelz',
            onPressed: () => setState(() => _showGehoelz = !_showGehoelz),
            tooltip: 'Gehölz Layer',
            child: Icon(Icons.forest),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'weg',
            onPressed: () => setState(() => _showWege = !_showWege),
            tooltip: 'Wege Layer',
            child: Icon(Icons.alt_route),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'gelaende',
            onPressed: () => setState(() => _showGelaende = !_showGelaende),
            tooltip: 'Gelände Layer',
            child: Icon(Icons.place),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'toggleMap',
            onPressed: () {
              setState(() {
                _mapStyle = MapStyle.values[
                  (_mapStyle.index + 1) % MapStyle.values.length
                ];
              });
            },
            tooltip: 'Kartenstil wechseln',
            child: Icon(Icons.layers),
          ),
        ],
      ),
    );
  }
}
