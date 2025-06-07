import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
// import 'package:timezone/browser.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  static Future<void> _configureLocalTimeZone() async {
    debugPrint("NotificationService: Initializing timezones data...");
    // --- PERBAIKAN PANGGILAN ---
    tz_data.initializeTimeZones(); // Gunakan alias tz_data
    // --- AKHIR PERBAIKAN PANGGILAN ---
    debugPrint("NotificationService: Timezones data initialized.");

    String? timeZoneName;
    try {
      debugPrint(
        "NotificationService: Attempting to get local timezone name...",
      );
      timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
      debugPrint(
        'NotificationService: Successfully got local timezone name: $timeZoneName',
      );
    } catch (e) {
      debugPrint('NotificationService: Could not get local timezone name: $e');
      timeZoneName = 'Etc/UTC'; // Fallback
      debugPrint(
        'NotificationService: Falling back to timezone: $timeZoneName',
      );
    }

    if (timeZoneName.isNotEmpty) {
      // Tambah pengecekan isNotEmpty
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint(
          'NotificationService: Local timezone configured to: ${tz.local.name}',
        );
      } catch (e) {
        debugPrint(
          'NotificationService: Failed to set local location for $timeZoneName: $e',
        );
        try {
          tz.setLocalLocation(tz.UTC);
          debugPrint(
            'NotificationService: As a last resort, local timezone set to UTC (tz.UTC).',
          );
        } catch (utcErr) {
          debugPrint(
            'NotificationService: CRITICAL - Failed to set even UTC as local timezone: $utcErr',
          );
        }
      }
    } else {
      debugPrint(
        'NotificationService: CRITICAL - Timezone name is null or empty, cannot set local location.',
      );
      try {
        tz.setLocalLocation(tz.UTC);
        debugPrint(
          'NotificationService: Timezone name was null/empty, local timezone set to UTC (tz.UTC).',
        );
      } catch (utcErr) {
        debugPrint(
          'NotificationService: CRITICAL - Failed to set even UTC as local timezone after null/empty name: $utcErr',
        );
      }
    }
  }

  static Future<void> initialize() async {
    // final String currentTimeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
    // tz_data.setLocalLocation(tz.getLocation(currentTimeZoneName));

    debugPrint("NotificationService: Starting initialization...");
    await _configureLocalTimeZone();
    debugPrint(
      "NotificationService: Local timezone configuration step finished. Current tz.local: ${tz.local.name}",
    );
  
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Ganti dengan ikon Anda

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          // onDidReceiveLocalNotification: (id, title, body, payload) async {
          //   // Handle notifikasi saat app di foreground di iOS versi lama
          // },
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsIOS,
        );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'daily_reminder_channel_id', // ID channel baru
            'Pengingat Harian',
            description: 'Pengingat harian untuk cek lowongan dan kos.',
            importance: Importance.defaultImportance, // Bisa disesuaikan
          ),
        );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            final String? payload = notificationResponse.payload;
            if (payload != null) {
              print('Notification payload (foreground/tap): $payload');
              // TODO: Handle navigasi berdasarkan payload jika perlu
              // Misal, jika payload 'open_app', cukup buka aplikasi.
            }
          },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(
    NotificationResponse notificationResponse,
  ) {
    print(
      'Notification Tapped in Background - payload: ${notificationResponse.payload}',
    );
    // TODO: Handle aksi background jika perlu
  }

  // --- FUNGSI BARU UNTUK MENJADWALKAN NOTIFIKASI HARIAN ---
  static Future<void> scheduleDailyReminderNotification({
    required int id, // ID unik untuk notifikasi ini, misal 0 untuk harian
    required String title,
    required String body,
    required TimeOfDay time, // Waktu notifikasi akan muncul setiap hari
    String? payload,
  }) async {
    // Dapatkan waktu TZDateTime untuk hari ini pada jam yang ditentukan
    // print("local time : ${tz.local}");
    TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // TZDateTime scheduledDate = now.add(
    //   Duration(seconds: 3),
    // );
    print("hari alarm notif = kokok = ${scheduledDate}");
    // if (scheduledDate.isBefore(now)) {
    //   scheduledDate = scheduledDate.add(const Duration(days: 1));
    // }
    print("hari alarm notif = kokok22 = ${scheduledDate}");
    print(
      'Notifikasi harian dijadwalkan untuk setiap hari jam: ${time.hour}:${time.minute}',
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel_id', // Gunakan ID channel yang sama
            'Pengingat Harian',
            channelDescription: 'Pengingat harian untuk cek lowongan dan kos.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default', // Suara default iOS
            presentAlert: true,
            presentBadge: true, // Bisa menampilkan badge di ikon app
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload ?? 'daily_reminder_payload',
      );
      print(
        'Notifikasi pengingat harian (ID: $id) berhasil dijadwalkan untuk ${DateFormat.yMd().add_Hms().format(scheduledDate)} dan akan berulang setiap hari pada waktu yang sama.',
      );
    } catch (e) {
      print('Error scheduling daily reminder notification: $e');
    }
  }

  // Fungsi untuk menampilkan notifikasi segera (jika masih diperlukan)
  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'immediate_channel', // ID channel bisa berbeda
    String channelName = 'Notifikasi Instan',
    String channelDesc = 'Notifikasi instan dari aplikasi.',
  }) async {
    // Buat channel jika belum ada (opsional, bisa juga di initialize)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDesc,
            importance: Importance.max,
          ),
        );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'immediate_channel', // Gunakan ID channel yang sesuai
          'Notifikasi Instan',
          channelDescription: 'Notifikasi instan dari aplikasi.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          ticker: 'ticker',
        );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      print('Notifikasi instan ditampilkan: $title');
    } catch (e) {
      print('Error menampilkan notifikasi instan: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print('Notifikasi dengan ID $id dibatalkan.');
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('Semua notifikasi dibatalkan.');
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notification_channel_id',
          'Instant Notifications',
          channelDescription: 'Instant notification channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
