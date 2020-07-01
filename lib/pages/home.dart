import 'dart:async';
import 'dart:convert';

import 'package:global_configuration/global_configuration.dart';
import 'package:async/async.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong/latlong.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jeepney_app/blocs/location_provider_bloc.dart';
import 'package:jeepney_app/blocs/preferences_bloc.dart';
import 'package:jeepney_app/blocs/request_manager_bloc.dart';
import 'package:jeepney_app/blocs/app_review_bloc.dart';
import 'package:jeepney_app/composite_subscription.dart';
import 'package:jeepney_app/keys.dart' as keys;
import 'package:jeepney_app/location/location_form_field.dart';
import 'package:jeepney_app/plan/plan.dart';
import 'package:jeepney_app/plan/plan_empty.dart';
import 'package:jeepney_app/trufi_localizations.dart';
import 'package:jeepney_app/trufi_models.dart';
import 'package:jeepney_app/widgets/alerts.dart';
import 'package:jeepney_app/widgets/trufi_drawer.dart';
import 'package:jeepney_app/widgets/app_review_dialog.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _data = HomePageStateData();
  final _formKey = GlobalKey<FormState>();
  final _fromFieldKey = GlobalKey<FormFieldState<TrufiLocation>>();
  final _toFieldKey = GlobalKey<FormFieldState<TrufiLocation>>();
  final _subscriptions = CompositeSubscription();

  bool _isFetching = false;
  CancelableOperation<Plan> _currentFetchPlanOperation;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscriptions.add(
      PreferencesBloc.of(context).outChangeOnline.listen((online) {
        if (_data.plan == null) {
          _fetchPlan();
        }
      }),
    );
    Future.delayed(Duration.zero, () {
      _loadState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscriptions.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final appReviewBloc = AppReviewBloc.of(context);
      if (await appReviewBloc.isAppReviewAppropriate()) {
        showAppReviewDialog(context);
        appReviewBloc.markReviewRequestedForCurrentVersion();
      }
    }
  }

  void _loadState() async {
    if (await _data.load(context) && _data.toPlace != null) {
      setState(() {
        _fromFieldKey.currentState?.didChange(_data.fromPlace);
        _toFieldKey.currentState?.didChange(_data.toPlace);
        if (_data.plan == null) {
          _fetchPlan();
        }
      });
    } else {
      _setFromPlaceToCurrentPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey(keys.homePage),
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      drawer: TrufiDrawer(HomePage.route),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return AppBar(
      bottom: PreferredSize(
        child: Container(),
        preferredSize: isPortrait
            ? Size.fromHeight(45.0)
            : Size.fromHeight(0.0),
      ),
      flexibleSpace: isPortrait
          ? _buildFormFieldsPortrait(context)
          : _buildFormFieldsLandscape(context),
    );
  }

  Widget _buildFormFieldsPortrait(BuildContext context) {
    final localizations = TrufiLocalizations.of(context);
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(12.0, 4.0, 4.0, 4.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildFormField(
                _fromFieldKey,
                ValueKey(keys.homePageFromPlaceField),
                localizations.searchPleaseSelectOrigin(),
                localizations.searchHintOrigin(),
                SvgPicture.asset(
                  "assets/images/from_marker.svg",
                  color: Theme.of(context).accentColor,
                  colorBlendMode: BlendMode.screen,
                ),
                _setFromPlace,
                leading: SizedBox.shrink(),
                trailing: _data.isResettable
                    ? _buildResetButton(context)
                    : null,
              ),
              _buildFormField(
                _toFieldKey,
                ValueKey(keys.homePageToPlaceField),
                localizations.searchPleaseSelectDestination(),
                localizations.searchHintDestination(),
                SvgPicture.asset(
                  "assets/images/to_marker.svg",
                  color: Theme.of(context).accentColor,
                  colorBlendMode: BlendMode.screen,
                ),
                _setToPlace,
                leading: SizedBox.shrink(),
                trailing: _data.isSwappable
                    ? _buildSwapButton(context, Orientation.portrait)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFieldsLandscape(BuildContext context) {
    final localizations = TrufiLocalizations.of(context);
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(12.0, 4.0, 4.0, 4.0),
        child: Form(
          key: _formKey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                width: 40.0,
                child: null,
              ),
              Flexible(
                flex: 1,
                child: _buildFormField(
                  _fromFieldKey,
                  ValueKey(keys.homePageFromPlaceField),
                  localizations.searchPleaseSelectOrigin(),
                  localizations.searchHintOrigin(),
                  SvgPicture.asset(
                    "assets/images/from_marker.svg",
                  ),
                  _setFromPlace,
                )
              ),
              SizedBox(
                width: 40.0,
                child: _data.isSwappable
                    ? _buildSwapButton(context, Orientation.landscape)
                    : null,
              ),
              Flexible(
                flex: 1,
                child: _buildFormField(
                  _toFieldKey,
                  ValueKey(keys.homePageToPlaceField),
                  localizations.searchPleaseSelectDestination(),
                  localizations.searchHintDestination(),
                  SvgPicture.asset(
                    "assets/images/to_marker.svg",
                  ),
                  _setToPlace,
                )
              ),
              SizedBox(
                width: 40.0,
                child: _data.isResettable
                    ? _buildResetButton(context)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwapButton(BuildContext context, Orientation orientation) {
    return FittedBox(
      child: IconButton(
        key: ValueKey(keys.homePageSwapButton),
        icon: Icon(
          orientation == Orientation.portrait
              ? Icons.swap_vert
              : Icons.swap_horiz,
          color: Theme.of(context).primaryIconTheme.color,
        ),
        onPressed: _swapPlaces,
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return FittedBox(
      child: IconButton(
        icon: Icon(
          Icons.clear,
          color: Theme.of(context).primaryIconTheme.color,
        ),
        onPressed: _reset,
      ),
    );
  }

  Widget _buildFormField(
    Key key,
    ValueKey<String> valueKey,
    String hintText,
    String searchHintText,
    SvgPicture textLeadingImage,
    Function(TrufiLocation) onSaved, {
    TrufiLocation initialValue,
    Widget leading,
    Widget trailing,
  }) {
    final children = <Widget>[];

    if (leading != null) {
      children.add(
        SizedBox(
          width: 40.0,
          child: leading,
        )
      );
    }

    children.add(
      Expanded(
        key: valueKey,
        child: LocationFormField(
          key: key,
          hintText: hintText,
          onSaved: onSaved,
          searchHintText: searchHintText,
          leadingImage: textLeadingImage,
        ),
      )
    );

    if (trailing != null) {
      children.add(
        SizedBox(
          width: 40.0,
          child: trailing,
        )
      );
    }

    return Row(
      children: children
    );
  }

  Widget _buildBody(BuildContext context) {
    Widget body = Container(
      child: _data.plan != null && _data.plan.error == null
          ? PlanPage(_data.plan)
          : PlanEmptyPage(onLongPress: _handleOnLongPress),
    );
    if (_isFetching) {
      return Stack(
        children: <Widget>[
          Positioned.fill(child: body),
          Positioned.fill(
            child: FlareActor(
              "assets/images/loading.flr",
              animation: "Trufi Drive",
            ),
          ),
        ],
      );
    } else {
      return body;
    }
  }

  void _handleOnLongPress(LatLng point) {
    _setToPlace(
      TrufiLocation.fromLatLng(
        TrufiLocalizations.of(context).searchMapMarker(),
        point,
      ),
    );
  }

  void _reset() {
    setState(() {
      _data.reset(context);
      _formKey.currentState.reset();
      _setFromPlaceToCurrentPosition();
    });
  }

  void _setPlaces(TrufiLocation fromPlace, TrufiLocation toPlace) {
    setState(() {
      _data.plan = null;
      _data.fromPlace = fromPlace;
      _data.toPlace = toPlace;
      _data.save(context);
      _toFieldKey.currentState.didChange(_data.toPlace);
      _fromFieldKey.currentState.didChange(_data.fromPlace);
      _fetchPlan();
    });
  }

  void _setFromPlace(TrufiLocation fromPlace) async {
    setState(() {
      _data.plan = null;
      _data.fromPlace = fromPlace;
      _data.save(context);
      _fromFieldKey.currentState.didChange(_data.fromPlace);
      _fetchPlan();
    });
  }

  void _setFromPlaceToCurrentPosition() async {
    final localizations = TrufiLocalizations.of(context);
    final location = await LocationProviderBloc.of(context).currentLocation;
    if (location != null) {
      _setFromPlace(
        TrufiLocation.fromLatLng(
          localizations.searchItemYourLocation(),
          location,
        ),
      );
    }
  }

  void _setToPlace(TrufiLocation toPlace) {
    setState(() {
      _data.plan = null;
      _data.toPlace = toPlace;
      _data.save(context);
      _toFieldKey.currentState.didChange(_data.toPlace);
      _fetchPlan();
    });
  }

  void _setPlan(Plan plan) {
    setState(() {
      _data.plan = plan;
      _data.save(context);
    });
  }

  void _swapPlaces() {
    _setPlaces(_data.toPlace, _data.fromPlace);
  }

  void _fetchPlan({bool car = false}) async {
    final requestManagerBloc = RequestManagerBloc.of(context);
    // Cancel the last fetch plan operation for replace with the current request
    if (_currentFetchPlanOperation != null) _currentFetchPlanOperation.cancel();
    final localizations = TrufiLocalizations.of(context);
    if (_data.toPlace != null && _data.fromPlace != null) {
      // Refresh your location
      final yourLocation = localizations.searchItemYourLocation();
      final refreshFromPlace = _data.fromPlace.description == yourLocation;
      final refreshToPlace = _data.toPlace.description == yourLocation;
      if (refreshFromPlace || refreshToPlace) {
        final location = await LocationProviderBloc.of(context).currentLocation;
        if (location != null) {
          if (refreshFromPlace) {
            _data.fromPlace = TrufiLocation.fromLatLng(yourLocation, location);
          }
          if (refreshToPlace) {
            _data.toPlace = TrufiLocation.fromLatLng(yourLocation, location);
          }
        } else {
          showDialog(
            context: context,
            builder: (context) => buildAlertLocationServicesDenied(context),
          );
          return; // Cancel fetch
        }
      }
      // Start fetch
      setState(() => _isFetching = true);
      try {
        _currentFetchPlanOperation = car
            ? requestManagerBloc.fetchCarPlan(
                context,
                _data.fromPlace,
                _data.toPlace,
              )
            : requestManagerBloc.fetchTransitPlan(
                context,
                _data.fromPlace,
                _data.toPlace,
              );
        Plan plan = await _currentFetchPlanOperation.valueOrCancellation(null);
        if (plan == null) {
          throw "Canceled by user";
        } else if (plan.hasError) {
          if (car) {
            _showErrorAlert(plan.error.message);
          } else {
            _showTransitErrorAlert(plan.error.message);
          }
        } else {
          _setPlan(plan);
          AppReviewBloc.of(context).incrementReviewWorthyActions();
        }
      } on FetchOfflineRequestException catch (e) {
        print("Failed to fetch plan: $e");
        _showOnAndOfflineErrorAlert(
          "Offline mode is not implemented yet.",
          false,
        );
      } on FetchOfflineResponseException catch (e) {
        print("Failed to fetch plan: $e");
        _showOnAndOfflineErrorAlert(
          "Offline mode is not implemented yet.",
          false,
        );
      } on FetchOnlineRequestException catch (e) {
        print("Failed to fetch plan: $e");
        _showOnAndOfflineErrorAlert(localizations.commonNoInternet(), true);
      } on FetchOnlineResponseException catch (e) {
        print("Failed to fetch plan: $e");
        _showOnAndOfflineErrorAlert(localizations.searchFailLoadingPlan(), true);
      } catch (e) {
        print("Failed to fetch plan: $e");
        _showErrorAlert(e.toString());
      }
      setState(() => _isFetching = false);
    }
  }

  void _showErrorAlert(String error) {
    showDialog(
      context: context,
      builder: (context) {
        return buildErrorAlert(context: context, error: error);
      },
    );
  }

  void _showTransitErrorAlert(String error) async {
    final location = await LocationProviderBloc.of(context).currentLocation;
    final languageCode = TrufiLocalizations.of(context).locale.languageCode;
    final packageInfo = await PackageInfo.fromPlatform();
    final urlRouteFeedback = GlobalConfiguration().getString("urlRouteFeedback");
    showDialog(
      context: context,
      builder: (context) {
        return buildTransitErrorAlert(
          context: context,
          error: error,
          onReportMissingRoute: () {
            launch(
              "$urlRouteFeedback?lang=$languageCode&geo=${location?.latitude},${location?.longitude}&app=${packageInfo.version}",
            );
          },
          onShowCarRoute: () {
            _fetchPlan(car: true);
          },
        );
      },
    );
  }

  void _showOnAndOfflineErrorAlert(String message, bool online) {
    final localizations = TrufiLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return buildOnAndOfflineErrorAlert(
          context: context,
          online: online,
          title: Text(localizations.commonError()),
          content: Text(message),
        );
      },
    );
  }
}

class HomePageStateData {
  static const String _FromPlace = "fromPlace";
  static const String _ToPlace = "toPlace";
  static const String _Plan = "plan";

  HomePageStateData({this.fromPlace, this.toPlace, this.plan});

  TrufiLocation fromPlace;
  TrufiLocation toPlace;
  Plan plan;

  // Json

  factory HomePageStateData.fromJson(Map<String, dynamic> json) {
    return HomePageStateData(
      fromPlace: TrufiLocation.fromJson(json[_FromPlace]),
      toPlace: TrufiLocation.fromJson(json[_ToPlace]),
      plan: Plan.fromJson(json[_Plan]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      _FromPlace: fromPlace != null ? fromPlace.toJson() : null,
      _ToPlace: toPlace != null ? toPlace.toJson() : null,
      _Plan: plan != null ? plan.toJson() : null,
    };
  }

  // Methods

  void reset(BuildContext context) async {
    fromPlace = null;
    toPlace = null;
    plan = null;
    PreferencesBloc.of(context).stateHomePage = null;
  }

  Future<bool> load(BuildContext context) async {
    try {
      HomePageStateData data = await compute(
        _parse,
        PreferencesBloc.of(context).stateHomePage,
      );
      if (data != null) {
        fromPlace = data.fromPlace;
        toPlace = data.toPlace;
        plan = data.plan;
        return true;
      }
    } catch (e) {
      print("Failed to load plan: $e");
    }
    return false;
  }

  void save(BuildContext context) async {
    PreferencesBloc.of(context).stateHomePage = json.encode(toJson());
  }

  // Getter

  bool get isSwappable => fromPlace != null && toPlace != null;

  bool get isResettable => toPlace != null || plan != null;
}

HomePageStateData _parse(String encoded) {
  if (encoded != null && encoded.isNotEmpty) {
    try {
      return HomePageStateData.fromJson(json.decode(encoded));
    } catch (e) {
      print("Failed to parse home page state data: $e");
    }
  }
  return HomePageStateData();
}
