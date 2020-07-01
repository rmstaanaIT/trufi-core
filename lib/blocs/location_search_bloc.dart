import 'package:flutter/material.dart';

import 'package:jeepney_app/blocs/bloc_provider.dart';
import 'package:jeepney_app/location/location_search_storage.dart';
import 'package:jeepney_app/trufi_models.dart';

class LocationSearchBloc extends BlocBase {
  static LocationSearchBloc of(BuildContext context) {
    return BlocProvider.of<LocationSearchBloc>(context);
  }

  LocationSearchBloc(BuildContext context) {
    storage.load(context, "assets/data/search.json");
  }

  final LocationSearchStorage storage = LocationSearchStorage();

  // Dispose

  @override
  void dispose() {}

  // Fetch

  Future<List<TrufiLocation>> fetchPlaces(BuildContext context) {
    return storage.fetchPlaces(context);
  }

  Future<List<LevenshteinObject>> fetchPlacesWithQuery(
    BuildContext context,
    String query,
  ) {
    return storage.fetchPlacesWithQuery(context, query);
  }

  Future<List<LevenshteinObject>> fetchStreetsWithQuery(
    BuildContext context,
    String query,
  ) {
    return storage.fetchStreetsWithQuery(context, query);
  }
}
