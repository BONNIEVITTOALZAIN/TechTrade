import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:techtrade/firebase_options.dart';
import 'package:techtrade/provider/app_theme.dart';
import 'package:techtrade/provider/theme_provider.dart';
import 'package:techtrade/screens/other/splash_screen.dart';
import 'package:intl/intl.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Izin notifikasi sementara diberikan');
  } else {
    print('Izin notifikasi ditolak');
  }
}

Future<void> showBasicNotification(String? title, String? body) async {
  final android = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: 'Notifikasi masuk dari FCM',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  final platform = NotificationDetails(android: android);
  await flutterLocalNotificationsPlugin.show(0, title, body, platform);
}

Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data['title'] ?? 'Pesan Baru';
  final body = data['body'] ?? '';
  final detail = data['detail'] ?? '';
  final sender = data['senderName'] ?? 'Pengirim tidak diketahui';
  final time = data['sendAt'] ?? '';
  final photoUrl = data['senderPhotoUrl'] ?? '';
  final formattedTime = DateFormat(
    'dd MMM yyyy, HH:mm',
  ).format(DateTime.parse(time));
  final String senderInfo = '📨 Dari: $sender\n🕒 Waktu: $formattedTime';

  ByteArrayAndroidBitmap? largeIconBitmap;
  if (photoUrl.isNotEmpty) {
    final base64 = await _networkImageToBase64(photoUrl);
    if (base64 != null) {
      largeIconBitmap = ByteArrayAndroidBitmap.fromBase64String(base64);
    }
  }

  final styleInfo =
      largeIconBitmap != null
          ? BigPictureStyleInformation(
            largeIconBitmap,
            largeIcon: largeIconBitmap,
            hideExpandedLargeIcon: true,
            contentTitle: 'Barang Baru',
            summaryText: '$senderInfo\n$body\n\nDetail:\n$detail',
          )
          : BigTextStyleInformation(
            '$senderInfo\n\nDetail:\n$body',
            contentTitle: '📢 $title',
          );

  final androidDetails = AndroidNotificationDetails(
    'detailed_channel',
    'Notifikasi Detail',
    channelDescription: 'Notifikasi dengan detail tambahan',
    styleInformation: styleInfo,
    largeIcon: largeIconBitmap,
    importance: Importance.max,
    priority: Priority.max,
  );

  final platform = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(1, title, body, platform);
}

Future<String?> _networkImageToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (_) {}
  return null;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data.isNotEmpty) {
    await showNotificationFromData(message.data);
  } else {
    await showBasicNotification(
      message.notification?.title,
      message.notification?.body,
    );
  }
}

Future<void> setupFirebaseMessaging() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  const String topic = "news";
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.subscribeToTopic(topic);
  print("Subscribed to topic: $topic");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      showNotificationFromData(message.data);
    } else {
      showBasicNotification(
        message.notification?.title,
        message.notification?.body,
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await requestNotificationPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings settings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(settings);

  await setupFirebaseMessaging();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TechTrade',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: SplashScreen(),
        );
      },
    );
  }
}
