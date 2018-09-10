import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:trufi_app/trufi_localizations.dart';

import 'package:trufi_app/trufi_models.dart';
import 'package:trufi_app/trufi_map_utils.dart';
import 'package:trufi_app/trufi_api.dart' as api;

class LinesMapController extends StatefulWidget {
  final LatLng initialPosition;

  LinesMapController({this.initialPosition});

  @override
  LinesMapControllerState createState() {
    return LinesMapControllerState();
  }
}

class LinesMapControllerState extends State<LinesMapController> {
  MapController mapController;
  List<Marker> _markers = List();
  List<Marker> _lineMarker = List();
  List<Stop> _stops = List();
  bool _showLinesNearby = false;
  Map<Stop, bool> _showNameForStop = Map();

  void initState() {
    super.initState();
    mapController = MapController()
      ..onReady.then((_) {
        setState(() {});
      });
  }

  Widget build(BuildContext context) {
    _markers.clear();
    _lineMarker.clear();

    if (_showLinesNearby == true) {
      for (Stop stop in _stops) {
        _markers.add(buildLineMarker(
            LatLng(stop.latitude, stop.longitude), Colors.black,
            onTap: () => _showName(stop)));

        _showNameForStop.forEach((stop, showName) {
          if (showName) {
            _lineMarker
                .add(_buildMarkerName(stop, onTap: () => _removeName(stop)));
          }
        });
      }
    }

    var bounds = LatLngBounds();
    _markers.forEach((marker) => bounds.extend(marker.point));

    if (widget.initialPosition != null) {
      _markers.add(buildYourLocationMarker(widget.initialPosition));
    }

    double buttonMargin = 20.0;
    double buttonPadding = 10.0;
    double buttonSize = 50.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              zoom: 5.0,
              maxZoom: 19.0,
              minZoom: 1.0,
            ),
            layers: [
              mapBoxTileLayerOptions(),
              MarkerLayerOptions(markers: _markers),
              MarkerLayerOptions(markers: _lineMarker),
            ],
          ),
        ),
        Positioned(
          top: buttonMargin,
          right: buttonMargin,
          width: buttonSize,
          height: buttonSize,
          child:
              _buildButton(Icons.my_location, _handleOnMyLocationButtonTapped),
        ),
        Positioned(
          top: buttonMargin + buttonPadding + buttonSize,
          right: buttonMargin,
          width: buttonSize,
          height: buttonSize,
          child: _buildButton(
              Icons.airport_shuttle, _handleOnNearLinesButtonTapped),
        ),
      ],
    );
  }

  Widget _buildButton(IconData iconData, Function onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        child: Icon(iconData),
      ),
    );
  }

  void _handleOnMyLocationButtonTapped() {
    mapController.move(widget.initialPosition, 17.0);
  }

  void _handleOnNearLinesButtonTapped() {
    _toggleShowLinesNearBy();
  }

  void _fetchNearStops() async {
    try {
      _setStops(await api.fetchStops(TrufiLocation.fromLatLng(
        TrufiLocalizations.of(context).searchCurrentPosition,
        widget.initialPosition,
      )));
    } on api.FetchRequestException catch (e) {
      print(e);
      //TODO: no internet
    } on api.FetchResponseException catch (e) {
      print(e);
      // TODO: no stops nearby
    }
  }

  void _setStops(List<Stop> stops) {
    setState(() {
      _stops = stops;
    });
  }

  void _toggleShowLinesNearBy() {
    setState(() {
      _showLinesNearby = !_showLinesNearby;
      if (_showLinesNearby == true) {
        _fetchNearStops();
      }
    });
  }

  void _showName(Stop stop) {
    setState(() {
      _showNameForStop.clear();
      _showNameForStop.addAll({stop: true});
    });
  }

  void _removeName(Stop stop) {
    setState(() {
      _showNameForStop.clear();
    });
  }
}

Marker buildLineMarker(LatLng point, Color color, {Function onTap}) {
  return new Marker(
    width: 30.0,
    height: 30.0,
    point: point,
    anchor: AnchorPos.center,
    builder: (context) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(4.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.directions_bus,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}

Marker _buildMarkerName(Stop stop, {Function onTap}) {
  LatLng point = LatLng(stop.latitude, stop.longitude);
  return new Marker(
    width: 40.0,
    height: 40.0,
    point: point,
    anchor: AnchorPos.center,
    builder: (context) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.deepOrangeAccent,
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: <Widget>[
                  Text(stop.name, style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
  );
}
