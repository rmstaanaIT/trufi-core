import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'package:jeepney_app/blocs/bloc_provider.dart';
import 'package:jeepney_app/location/location_storage.dart';
import 'package:jeepney_app/trufi_models.dart';

abstract class LocationsBlocBase implements BlocBase {
  LocationsBlocBase(BuildContext context, this.locationStorage) {
    _addLocationController.listen(_handleAdd);
    _removeLocationController.listen(_handleRemove);
    locationStorage.load(context).then((_) => _notify);
  }

  final LocationStorage locationStorage;

  // AddLocation
  final _addLocationController = BehaviorSubject<TrufiLocation>();

  Sink<TrufiLocation> get inAddLocation => _addLocationController.sink;

  // RemoveLocation
  final _removeLocationController = BehaviorSubject<TrufiLocation>();

  Sink<TrufiLocation> get inRemoveLocation => _removeLocationController.sink;

  // Locations
  final _locationsController = BehaviorSubject<List<TrufiLocation>>(
    seedValue: [],
  );

  Sink<List<TrufiLocation>> get _inLocations => _locationsController.sink;

  Stream<List<TrufiLocation>> get outLocations => _locationsController.stream;

  // Dispose

  @override
  void dispose() {
    _addLocationController.close();
    _removeLocationController.close();
    _locationsController.close();
  }

  // Handle

  void _handleAdd(TrufiLocation value) {
    locationStorage.add(value);
    _notify();
  }

  void _handleRemove(TrufiLocation value) {
    locationStorage.remove(value);
    _notify();
  }

  void _notify() {
    _inLocations.add(locations);
  }

  // Getter

  List<TrufiLocation> get locations => locationStorage.unmodifiableListView;

  // Fetch

  Future<List<TrufiLocation>> fetch(BuildContext context) {
    return locationStorage.fetchLocations(context);
  }

  Future<List<LevenshteinObject>> fetchWithQuery(
    BuildContext context,
    String query,
  ) {
    return locationStorage.fetchLocationsWithQuery(context, query);
  }

  Future<List<TrufiLocation>> fetchWithLimit(
    BuildContext context,
    int limit,
  ) {
    return locationStorage.fetchLocationsWithLimit(context, limit);
  }
}

int sortByLocations(
  dynamic a,
  dynamic b,
  List<TrufiLocation> locations,
) {
  bool aIsAvailable = (a is TrufiLocation)
      ? locations.contains(a)
      : (a is TrufiStreet)
          ? a.junctions.fold<bool>(
              false,
              (result, j) => result |= locations.contains(j.location),
            )
          : false;
  bool bIsAvailable = (b is TrufiLocation)
      ? locations.contains(b)
      : (b is TrufiStreet)
          ? b.junctions.fold<bool>(
              false,
              (result, j) => result |= locations.contains(j.location),
            )
          : false;
  return aIsAvailable == bIsAvailable ? 0 : aIsAvailable ? -1 : 1;
}
