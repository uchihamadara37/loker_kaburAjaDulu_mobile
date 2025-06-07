
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/browser.dart';

// final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

// class NotifService{
//   static Future<void> initialize() async {
//     // initialize timezon
//     initializeTimeZone();
//     //! https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
//     setLocalLocation(getLocation('Asia/Jakarta'));

//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/launcher_icon',
//     );
//     const DarwinInitializationSettings iosSettings =
//         DarwinInitializationSettings();
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: androidSettings, iOS: iosSettings);

//     await notificationsPlugin.initialize(initializationSettings);

//   }
//   // Future<void> init() async {
//   // }

//   static Future<void> showInstantNotification({
//     required int id,
//     required String title,
//     required String body,
//   }) async {
//     await notificationsPlugin.show(
//       id,
//       title,
//       body,
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'instant_notification_channel_id',
//           'Instant Notifications',
//           channelDescription: 'Instant notification channel',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(),
//       ),
//     );
//   }

// }