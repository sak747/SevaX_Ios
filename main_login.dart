import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'package:sevaexchange/auth/auth.dart';
import 'package:sevaexchange/auth/auth_provider.dart';
import 'package:sevaexchange/flavor_config.dart';
import 'package:sevaexchange/l10n/l10n.dart';
import 'package:sevaexchange/localization/applanguage.dart';
import 'package:sevaexchange/localization/app_timezone.dart';
import 'package:sevaexchange/ui/screens/auth/bloc/user_bloc.dart';
import 'package:sevaexchange/ui/screens/home_page/bloc/home_page_base_bloc.dart';
import 'package:sevaexchange/ui/screens/members/bloc/members_bloc.dart';
import 'package:sevaexchange/utils/connectivity.dart';
import 'package:sevaexchange/utils/app_config.dart';
import 'package:sevaexchange/views/login/login_page.dart';
import 'package:sevaexchange/widgets/customise_community/theme_bloc.dart';
import 'package:sevaexchange/utils/connectivity_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sevaexchange/models/user_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize flavor config
  FlavorConfig.appFlavor = Flavor.APP;

  // Initialize connectivity
  ConnectionStatusSingleton connectionStatus =
      ConnectionStatusSingleton.getInstance();
  await connectionStatus.initialize();

  // Initialize app config manually
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  AppConfig.appVersion = packageInfo.version;
  AppConfig.buildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
  AppConfig.packageName = packageInfo.packageName;
  AppConfig.prefs = await SharedPreferences.getInstance();

  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MembersBloc>(
          create: (context) => MembersBloc(),
          dispose: (_, MembersBloc b) => b.dispose(),
        ),
        Provider(
          create: (context) => HomePageBaseBloc(),
          dispose: (_, HomePageBaseBloc? b) => b?.dispose(),
        ),
        Provider(
          create: (context) => UserBloc(),
          dispose: (_, UserBloc? b) => b?.dispose(),
        ),
        ChangeNotifierProvider<ThemeBloc>(
          create: (context) => ThemeBloc(),
        ),
        ChangeNotifierProvider<AppLanguage>(
          create: (context) => AppLanguage(),
        ),
        ChangeNotifierProvider<AppTimeZone>(
          create: (context) => AppTimeZone(),
        ),
      ],
      child: AuthProvider(
        auth: Auth(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CustomLoginPage(),
        ),
      ),
    );
  }
}

class CustomLoginPage extends StatefulWidget {
  @override
  _CustomLoginPageState createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }

  void _processLogin(UserModel userModel) {
    // Override to show success message instead of navigating to full app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login successful for ${userModel.email}'),
        duration: Duration(seconds: 3),
      ),
    );
    // Reset loading state
    setState(() {
      _isLoading = false;
    });
  }
}
