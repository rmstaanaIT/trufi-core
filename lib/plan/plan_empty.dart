import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong/latlong.dart';
import 'package:trufi_app/trufi_map_utils.dart';

import 'package:trufi_app/widgets/trufi_map.dart';
import 'package:trufi_app/widgets/trufi_online_map.dart';

class PlanEmptyPage extends StatefulWidget {
  PlanEmptyPage({this.initialPosition});

  final LatLng initialPosition;

  @override
  PlanEmptyPageState createState() => PlanEmptyPageState();
}

class PlanEmptyPageState extends State<PlanEmptyPage>
    with TickerProviderStateMixin {
  final _trufiMapController = TrufiMapController();
  Marker _fromMarker;
  Marker _chooseOnMapMarker;

  @override
  Widget build(BuildContext context) {
    List<Polyline> polylines = [];
    List<Marker> markers = [];
    Widget _confirmationDestination = Container();
    if (widget.initialPosition != null) {
      _fromMarker = buildFromMarker(widget.initialPosition);
      if (_chooseOnMapMarker != null) {
        polylines.add(Polyline(
          points: [_fromMarker.point, _chooseOnMapMarker.point],
          isDotted: true,
          color: Color(0xffd81b60),
          strokeWidth: 5,
        ));
        markers = [_fromMarker, _chooseOnMapMarker];
        _confirmationDestination = Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: RaisedButton(
              color: Color(0xffd81b60),
              child: Text(
                "CONFIRM DESTINATION",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {},
            ),
          ),
        );
      }
    }
    return Stack(
      children: <Widget>[
        TrufiOnlineMap(
          key: ValueKey("PlanEmptyMap"),
          controller: _trufiMapController,
          onPositionChanged: _handleOnMapPositionChanged,
          layerOptionsBuilder: (context) {
            return <LayerOptions>[
              _trufiMapController.yourLocationLayer,
              PolylineLayerOptions(polylines: polylines),
              MarkerLayerOptions(markers: markers),
            ];
          },
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: _buildFloatingActionButton(context),
        ),
        _confirmationDestination,
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Theme.of(context).backgroundColor,
      child: Icon(Icons.my_location, color: Colors.black),
      onPressed: _handleOnYourLocationPressed,
      heroTag: null,
    );
  }

  void _handleOnYourLocationPressed() async {
    _trufiMapController.moveToYourLocation(
      context: context,
      tickerProvider: this,
    );
  }

  void _handleOnMapPositionChanged(MapPosition position, bool hasGesture) {
    setState(() {
      if (widget.initialPosition != null) {
        _chooseOnMapMarker = buildToMarker(position.center);
      } else {
        _chooseOnMapMarker = null;
      }
    });
  }
}
