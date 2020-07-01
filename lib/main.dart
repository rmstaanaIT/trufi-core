import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jeepney_app/blocs/app_review_bloc.dart';

import 'package:jeepney_app/blocs/bloc_provider.dart';
import 'package:jeepney_app/blocs/favorite_locations_bloc.dart';
import 'package:jeepney_app/blocs/history_locations_bloc.dart';
import 'package:jeepney_app/blocs/location_provider_bloc.dart';
import 'package:jeepney_app/blocs/location_search_bloc.dart';
import 'package:jeepney_app/blocs/preferences_bloc.dart';
import 'package:jeepney_app/blocs/request_manager_bloc.dart';
import 'package:jeepney_app/pages/about.dart';
import 'package:jeepney_app/pages/feedback.dart';
import 'package:jeepney_app/pages/home.dart';
import 'package:jeepney_app/pages/team.dart';
import 'package:jeepney_app/pages/website.dart';
import 'package:jeepney_app/trufi_localizations.dart';
import 'package:jeepney_app/widgets/toggle_class.dart';
import 'package:jeepney_app/widgets/trufi_drawer.dart';

void main() async {
  await GlobalConfiguration().loadFromAsset("app_config");
  runApp(TrufiApp());
}

class TrufiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final preferencesBloc = PreferencesBloc();
    return BlocProvider<PreferencesBloc>(
      bloc: preferencesBloc,
      child: BlocProvider<AppReviewBloc>(
        bloc: AppReviewBloc(preferencesBloc),
        child: BlocProvider<RequestManagerBloc>(
          bloc: RequestManagerBloc(preferencesBloc),
          child: BlocProvider<LocationProviderBloc>(
            bloc: LocationProviderBloc(),
            child: BlocProvider<LocationSearchBloc>(
              bloc: LocationSearchBloc(context),
              child: BlocProvider<FavoriteLocationsBloc>(
                bloc: FavoriteLocationsBloc(context),
                child: BlocProvider<HistoryLocationsBloc>(
                  bloc: HistoryLocationsBloc(context),
                  child: AppLifecycleReactor(
                    child: LocalizedMaterialApp(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppLifecycleReactor extends StatefulWidget {
  const AppLifecycleReactor({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _AppLifecycleReactorState createState() => _AppLifecycleReactorState();
}

class _AppLifecycleReactorState extends State<AppLifecycleReactor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  AppLifecycleState _notification;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final locationProviderBloc = LocationProviderBloc.of(context);
    print("AppLifecycleState: $state");
    setState(() {
      _notification = state;
      if (_notification == AppLifecycleState.resumed) {
        locationProviderBloc.start();
      } else {
        locationProviderBloc.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class LocalizedMaterialApp extends StatefulWidget {
  @override
  _LocalizedMaterialAppState createState() => _LocalizedMaterialAppState();
}

class _LocalizedMaterialAppState extends State<LocalizedMaterialApp> {
  String isOnnn = ToggleClass.isOnn.toString();


  @override
  Widget build(BuildContext context) {
    final preferencesBloc = PreferencesBloc.of(context);

    final theme = ThemeData(
//      primaryColor:  const Color(0xFF1C344C) ,
      primaryColor:  const Color(0xFF3D485E) ,
//      primaryColorLight: const Color(0xffeceff1),
      primaryColorLight: const Color(0xFF829191),
//      accentColor: const Color(0xFFE63D3D),
      accentColor: const Color(0xFFAC3931),

      backgroundColor: Colors.white,
      textTheme: TextTheme(
        subhead:
        Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
        headline:
        Theme.of(context).textTheme.headline.copyWith(color: Colors.white),
        title: Theme.of(context).textTheme.title.copyWith(color: Colors.white),
        body1: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
//        body2: Theme.of(context).textTheme.body2.copyWith(color: Colors.black),
        body2: Theme.of(context).textTheme.body2.copyWith(color: Color(0xFF1E232F)),

      ),

    );



    final routes = <String, WidgetBuilder>{
      AboutPage.route: (context) => AboutPage(),
      FeedbackPage.route: (context) => FeedbackPage(),
      TeamPage.route: (context) => TeamPage(),
    // WebsitePage.route: (context) => WebsitePage(),
    };
    return StreamBuilder(
      stream: preferencesBloc.outChangeLanguageCode,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return MaterialApp(
          onGenerateRoute: (settings) {
            return new TrufiDrawerRoute(
              builder: routes[settings.name],
              settings: settings,
            );
          },
          localizationsDelegates: [
            TrufiLocalizationsDelegate(snapshot.data),
            TrufiMaterialLocalizationsDelegate(snapshot.data),
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: HomePage(),
        );
      },
    );
  }
}
