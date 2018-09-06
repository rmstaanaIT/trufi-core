import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:trufi_app/trufi_localizations.dart';

import 'package:trufi_app/trufi_models.dart';
import 'package:trufi_app/trufi_map_utils.dart';
import 'package:trufi_app/trufi_api.dart' as api;

typedef void OnSelected(PlanItinerary itinerary);

class LinesMapController extends StatefulWidget {
  final Plan plan;
  final OnSelected onSelected;
  final LatLng yourLocation;
  final PlanItinerary selectedItinerary;

  LinesMapController(
      {this.plan, this.onSelected, this.yourLocation, this.selectedItinerary});

  @override
  LinesMapControllerState createState() {
    return LinesMapControllerState();
  }
}

class LinesMapControllerState extends State<LinesMapController> {
  MapController mapController;

  List<Stop> _stops = List();
  List<Marker> _markers = List();
  bool _needsCameraUpdate = true;

  void initState() {
    super.initState();
    mapController = MapController()
      ..onReady.then((_) {
        setState(() {});
      });
  }

  Widget build(BuildContext context) {
    _needsCameraUpdate = _needsCameraUpdate;
    _markers.clear();

    var bounds = LatLngBounds();

    _markers.forEach((marker) => bounds.extend(marker.point));

    if (widget.yourLocation != null) {
      _markers.add(buildYourLocationMarker(widget.yourLocation));
    }
    if (_needsCameraUpdate && mapController.ready) {
      if (bounds.isValid) {
        mapController.fitBounds(bounds);
      } else if (widget.yourLocation != null) {
        // TODO during the initial phase this code fails - don't know why
        try {
          mapController.move(widget.yourLocation, 15.0);
        } catch (e) {}
      }
      _needsCameraUpdate = false;
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
            ],
          ),
        ),
        Positioned(
          top: buttonMargin ,
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
          child:
          _buildButton(Icons.airport_shuttle, _handleOnNearLinesButtonTapped),
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
    mapController.move(widget.yourLocation, 17.0);
  }

  void _handleOnNearLinesButtonTapped() {
    _fetchNearStops();
  }

  _fetchNearStops() async {
    try {
      _setMarkersStops(await api.fetchStops(TrufiLocation.fromLatLng(
        TrufiLocalizations.of(context).searchCurrentPosition,
        widget.yourLocation,
      )));
    } on api.FetchRequestException catch (e) {
      print(e);
      /*_setMarkersStops(
          Stop.fromError(TrufiLocalizations.of(context).commonNoInternet));*/
    } on api.FetchResponseException catch (e) {
      print(e);
     /* _setMarkersStops(Stop.fromError(
          TrufiLocalizations.of(context).searchFailLoadingPlan));*/
    }
  }

  void _setMarkersStops(List<Stop> stop) {
    print("set markers");
  }
}
