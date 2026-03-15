import 'package:flowchat/config/Logger.dart';
import 'package:flowchat/config/app_style.dart';
import 'package:flowchat/config/environment.dart';
import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/screens/auth_screen_new.dart';
import 'package:flowchat/screens/profile_setup_screen.dart';
import 'package:flowchat/screens/chat_list_screen.dart';
import 'package:flowchat/services/chat_repository.dart';
import 'package:flowchat/services/db_service.dart';
import 'package:flowchat/services/web_socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final ChatRepository _repo = ChatRepository();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await DbService().init();

  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});
  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  MyAccount? myAccount;
  MyAccount? dbMyAccount;
  bool _isDbChecked = false;

  // FIX: Use a unique key for MaterialApp to force a clean slate on logout
  Key _appKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    Logger.log("main","env=${Environment.environment}");
    _checkAndSetAccount();
  }

  Future<void> _checkAndSetAccount() async {
    final accList = await _repo.getAllMyAccount();
    setState(() {
      if (accList.isNotEmpty) {
        dbMyAccount = accList.first;
      } else {
        dbMyAccount = null; // Ensure null if empty
      }
      _isDbChecked = true;
    });
  }

  // FIX: Clean reset for logout
  void restartApp() {
    setState(() {
      myAccount = null;
      dbMyAccount = null;
      _isDbChecked = false;
      _appKey = UniqueKey(); // Force MaterialApp to dispose of all old keys
    });
    _checkAndSetAccount();
  }

  Future<void> _onLogin(String contactNo) async {
    final fetchedAccount = await _repo.fetchUserFromApi(contactNo);
    if (fetchedAccount != null) {
      setState(() => myAccount = fetchedAccount);
    }
  }

  @override
  void dispose() {
    WebSocketService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isTablet = constraints.maxWidth > 600;

      if (!_isDbChecked) {
        return MaterialApp(
          key: const ValueKey('loading'),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppStyle.primaryColor,
              ),
            ),
          ),
        );
      }

      return MaterialApp(
        key: _appKey, // FIX: Apply the UniqueKey here
        title: 'FlowChat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppStyle.primaryColor,
            primary: AppStyle.primaryColor,
            secondary: AppStyle.secondaryColor,
            surface: const Color(0xFFF8FAFC),
          ),
          appBarTheme: AppBarTheme(
            centerTitle: isTablet,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.bold),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        home: dbMyAccount != null
            ? ChatListScreen(myAccount: dbMyAccount!)
            : (myAccount == null
            ? AuthScreenNew(onLogin: _onLogin)
            : ProfileSetupScreen(
          myAccount: myAccount!,
          isNewProfile: true,
        )),
      );
    });
  }
}