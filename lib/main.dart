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

  // Set system navigation bar and status bar to be transparent/clean
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
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

  @override
  void initState() {
    super.initState();
    Logger.log("main","env=${Environment.environment}");
    Logger.log("main","hostApiUrl=${Environment.hostApiUrl}");
    Logger.log("main","socketUrl=${Environment.socketUrl}");
    Logger.log("main","debugMode=${Environment.debugMode}");
    _checkAndSetAccount();
  }

  Future<void> _checkAndSetAccount() async {
    final accList = await _repo.getAllMyAccount();
    if (accList.isNotEmpty) {
      dbMyAccount = accList.first;
      WebSocketService().connect(dbMyAccount!.contactNo);
    }
    setState(() => _isDbChecked = true);
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
    // Unique Social/Friendship Color Palette (Coral & Sunset)
    const primaryBrandColor = AppStyle.primaryColor; // Soft Coral
    const secondaryBrandColor = AppStyle.secondaryColor; // Warm Sunny Yellow

    if (!_isDbChecked) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Friendship Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrandColor,
          primary: primaryBrandColor,
          secondary: secondaryBrandColor,
          surface: Colors.white,
        ),
        // Modernized AppBar for social feel
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800, // Thicker font for social "vibes"
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        // Rounded Buttons for friendliness
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        // Soften Input decorations
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: dbMyAccount != null
          ? ChatListScreen(myAccount: dbMyAccount!)
          : (myAccount == null
          ? AuthScreenNew(onLogin: _onLogin)
          : ProfileSetupScreen(myAccount: myAccount!,isNewProfile: true,)),
    );
  }
}