import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/account_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/account/booked_kos_list_screen.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/account/fullmap_booked_kos_screen.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/account/kesan_saran_screen.dart';
import 'package:loker_kabur_aja_dulu/services/currency_service.dart';
// import 'package:loker_kabur_aja_dulu/data/models/kos_dipesan_model.dart';
// import 'package:loker_kabur_aja_dulu/presentation/screens/kos/kos_detail_screen.dart'; // Untuk navigasi ke detail kos
// import 'package:loker_kabur_aja_dulu/services/notif_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang dan tanggal
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'as fln;

import 'package:loker_kabur_aja_dulu/services/notification_service.dart'; // Import NotificationService
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';



class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _topUpAmountController = TextEditingController();
  // final _formKey = GlobalKey<FormState>();
  final _topUpDialogFormKey = GlobalKey<FormState>();

  bool _dailyReminderEnabled = false; // State untuk status penjadwalan
  TimeOfDay? _selectedReminderTime;

  static const int DAILY_REMINDER_ID = 1;
  static const String PREF_REMINDER_ENABLED = 'dailyReminderEnabled';
  static const String PREF_REMINDER_HOUR = 'dailyReminderHour';
  static const String PREF_REMINDER_MINUTE = 'dailyReminderMinute';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccountData();
      _loadReminderPreferences();
    });
  }

  Future<void> _loadReminderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminderEnabled = prefs.getBool(PREF_REMINDER_ENABLED) ?? false;
      final hour = prefs.getInt(PREF_REMINDER_HOUR);
      final minute = prefs.getInt(PREF_REMINDER_MINUTE);
      if (hour != null && minute != null) {
        _selectedReminderTime = TimeOfDay(hour: hour, minute: minute);
      } else {
        _selectedReminderTime = const TimeOfDay(
          hour: 9,
          minute: 0,
        ); // Default jika belum di-set
      }
    });
    // Cek juga apakah notifikasi memang terjadwal di sistem (opsional, untuk sinkronisasi lebih kuat)
    // _checkIfActualNotificationIsScheduled();
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'PILIH WAKTU PENGINGAT HARIAN',
    );

    if (pickedTime != null && pickedTime != _selectedReminderTime) {
      setState(() {
        _selectedReminderTime = pickedTime;
      });
      // Jika pengingat sudah aktif, langsung update jadwalnya
      if (_dailyReminderEnabled) {
        _scheduleOrCancelDailyReminder(
          true,
        ); // Jadwalkan ulang dengan waktu baru
        print("berhasil dijadwalkan baru mase: alarm");
      }
      _saveReminderPreferences(); // Simpan waktu baru
    }
  }

  Future<void> _saveReminderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_REMINDER_ENABLED, _dailyReminderEnabled);
    if (_selectedReminderTime != null) {
      await prefs.setInt(PREF_REMINDER_HOUR, _selectedReminderTime!.hour);
      await prefs.setInt(PREF_REMINDER_MINUTE, _selectedReminderTime!.minute);
    } else {
      await prefs.remove(PREF_REMINDER_HOUR);
      await prefs.remove(PREF_REMINDER_MINUTE);
    }
  }

  Future<void> _scheduleOrCancelDailyReminder(bool enable) async {
    setState(() {
      _dailyReminderEnabled = enable;
    });
    await _saveReminderPreferences();

    if (enable) {
      if (_selectedReminderTime == null) {
        // Seharusnya tidak terjadi jika UI sudah benar, tapi sebagai fallback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan atur waktu pengingat terlebih dahulu.'),
          ),
        );
        setState(() {
          _dailyReminderEnabled = false;
        }); // Matikan lagi switch-nya
        await _saveReminderPreferences();
        return;
      }
      // Gunakan fln.Time dari flutter_local_notifications
      // final fln. notificationTime = fln.Time(_selectedReminderTime!.hour, _selectedReminderTime!.minute, 0);
      print("siap membuat reminder mase");
      await NotificationService.scheduleDailyReminderNotification(
        id: DAILY_REMINDER_ID,
        title: 'Jangan Lewatkan Kesempatan!',
        body: 'Yuk, cek lowongan kerja dan info kos terbaru di KaburAjaDulu!',
        time: TimeOfDay(
          hour: _selectedReminderTime!.hour,
          minute: _selectedReminderTime!.minute,
        ),
        // payload: 'daily_reminder_tap',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengingat harian diaktifkan untuk jam ${_selectedReminderTime!.format(context)}.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await NotificationService.cancelNotification(DAILY_REMINDER_ID);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengingat harian dinonaktifkan.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadAccountData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    if (authProvider.isAuthenticated && authProvider.userId != null) {
      await accountProvider.fetchCurrentUserSaldo(authProvider.userId!);
      await accountProvider.fetchBookedKos(authProvider.userId!);
    }
  }

  // Future<void> _checkIfDailyReminderIsScheduled() async {
  //   final List<PendingNotificationRequest> pendingRequests =
  //       await NotificationService.getPendingNotifications();

  //   bool found = false;
  //   for (var request in pendingRequests) {
  //     if (request.id == DAILY_REMINDER_ID) {
  //       found = true;
  //       break;
  //     }
  //   }
  //   if (mounted) {
  //     setState(() {
  //       _dailyReminderEnabled = found;
  //     });
  //   }
  // }
  // Future<void> _toggleDailyReminder(bool enable) async {
  //   if (enable) {
  //     await NotificationService.scheduleDailyReminderNotification(
  //       id: DAILY_REMINDER_ID,
  //       title: 'Jangan Lewatkan Kesempatan!',
  //       body: 'Yuk, cek lowongan kerja dan info kos terbaru di KaburAjaDulu!',
  //       time: const TimeOfDay(hour: 0, minute: 0),
  //       payload: 'daily_reminder_tap',
  //     );
  //     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengingat harian diaktifkan untuk jam 9 pagi.'), backgroundColor: Colors.green,));
  //   } else {
  //     await NotificationService.cancelNotification(DAILY_REMINDER_ID);
  //     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengingat harian dinonaktifkan.'), backgroundColor: Colors.orange,));
  //   }
  //   _checkIfDailyReminderIsScheduled();
  // }

  @override
  void dispose() {
    _topUpAmountController.dispose();
    super.dispose();
  }

  void _showTopUpDialog(
    BuildContext context,
    AccountProvider accountProvider,
    String userId,
  ) {
    final currencyService = CurrencyService();
    final List<String> availableCurrencies = ['IDR', 'USD', 'EUR', 'JPY', 'GBP', 'SGD', 'MYR', 'AUD'];
    
    // State untuk dialog, dideklarasikan di luar StatefulBuilder
    String selectedTopUpCurrency = 'IDR';
    double? rateFromSelectedToIDR = 1.0; // Default untuk IDR ke IDR
    bool isLoadingConversion = false;
    String? conversionError;
    bool isInitialFetchDone = false;

    // Bersihkan controller sebelum menampilkan dialog
    _topUpAmountController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctxDialog) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {

            void fetchRate() {
              if (selectedTopUpCurrency == 'IDR') {
                setStateDialog(() {
                  rateFromSelectedToIDR = 1.0;
                  isLoadingConversion = false;
                  conversionError = null;
                });
                return;
              }
              
              setStateDialog(() {
                isLoadingConversion = true;
                conversionError = null;
                rateFromSelectedToIDR = null;
              });

              currencyService.getConversionRates(
                baseCurrency: selectedTopUpCurrency,
                targetCurrencies: ['IDR'],
              ).then((rates) {
                if(mounted) {
                   setStateDialog(() {
                    rateFromSelectedToIDR = rates['IDR'];
                    isLoadingConversion = false;
                  });
                }
              }).catchError((e) {
                if(mounted) {
                   setStateDialog(() {
                    conversionError = e.toString();
                    isLoadingConversion = false;
                  });
                }
              });
            }
            
            if (!isInitialFetchDone) {
              isInitialFetchDone = true;
              // Panggil fetchRate di sini jika default bukan IDR,
              // tapi karena defaultnya IDR, rate-nya sudah 1.0, jadi tidak perlu fetch.
            }

            double inputAmount = double.tryParse(_topUpAmountController.text) ?? 0.0;
            double finalAmountInIDR = inputAmount * (rateFromSelectedToIDR ?? 0.0);
            
            final currencyFormatterIDR = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

            return AlertDialog(
              title: const Text('Top Up Saldo'),
              content: Form(
                key: _topUpDialogFormKey, // Gunakan key yang berbeda
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedTopUpCurrency,
                        decoration: const InputDecoration(labelText: 'Pilih Mata Uang'),
                        items: availableCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (newValue) {
                          if (newValue != null && newValue != selectedTopUpCurrency) {
                            selectedTopUpCurrency = newValue;
                            fetchRate();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _topUpAmountController,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Top Up',
                          prefixText: '$selectedTopUpCurrency ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Masukkan jumlah.';
                          if ((double.tryParse(v) ?? 0) <= 0) return 'Jumlah tidak valid.';
                          return null;
                        },
                        onChanged: (value) {
                           // Memicu rebuild untuk update teks konversi
                           setStateDialog(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isLoadingConversion)
                        const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                      else if (conversionError != null)
                        Text('Gagal memuat kurs: $conversionError', style: const TextStyle(color: Colors.redAccent))
                      else if (rateFromSelectedToIDR != null && selectedTopUpCurrency != 'IDR')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            'Akan dikonversi menjadi:\n${currencyFormatterIDR.format(finalAmountInIDR)}',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        )
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(ctxDialog).pop(),
                ),
                ElevatedButton(
                  onPressed: (isLoadingConversion || accountProvider.isProcessingTopUp || rateFromSelectedToIDR == null) 
                    ? null 
                    : () async {
                      if (_topUpDialogFormKey.currentState!.validate()) {
                        final success = await accountProvider.topUpSaldo(userId, finalAmountInIDR);
                        if (mounted) {
                          Navigator.of(ctxDialog).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Top up berhasil!' : accountProvider.errorMessage ?? 'Top up gagal.'),
                              backgroundColor: success ? Colors.green : Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                  child: isLoadingConversion
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Top Up'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final user = authProvider.currentUser;

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (!authProvider.isAuthenticated ||
        user == null ||
        authProvider.userId == null) {
      return const Center(
        child: Text('Silakan login untuk mengakses halaman akun.'),
      );
    }

    return Scaffold(
      // AppBar sudah ada di HomeScreen
      body: RefreshIndicator(
        onRefresh: _loadAccountData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Agar RefreshIndicator selalu aktif
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Bagian Profil Pengguna ---
              Center(
                child: Column(
                  children: [
                    if (user.fotoProfile != null &&
                        user.fotoProfile!.isNotEmpty)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(user.fotoProfile!),
                        onBackgroundImageError: (e, s) =>
                            const Icon(Icons.person, size: 50),
                      )
                    else
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      user.nama,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Role: ${user.role}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (user.linkLinkedIn != null &&
                        user.linkLinkedIn!.isNotEmpty)
                      InkWell(
                        onTap: () async {
                          final Uri url = Uri.parse(user.linkLinkedIn!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tidak bisa membuka link: ${user.linkLinkedIn}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'LinkedIn: ${user.linkLinkedIn}',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 32, thickness: 1),

              // --- Bagian Saldo ---
              Text('Saldo Anda', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      accountProvider.isLoadingSaldo
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              currencyFormatter.format(
                                accountProvider.currentUserSaldo?.saldo ?? 0,
                              ),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_card_outlined),
                        label: const Text('Top Up'),
                        onPressed: () => _showTopUpDialog(
                          context,
                          accountProvider,
                          authProvider.userId!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (accountProvider.errorMessage != null &&
                  !accountProvider.isLoadingSaldo &&
                  !accountProvider.isProcessingTopUp)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Error Saldo: ${accountProvider.errorMessage}",
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const Divider(height: 32, thickness: 1),

              // --- Bagian Daftar Kos Dipesan ---
              ListTile(
                leading: const Icon(
                  Icons.bookmark_added_outlined,
                  color: Colors.teal,
                  size: 35,
                ),
                title: const Text(
                  'Kos Dipesan (DP Lunas)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${accountProvider.bookedKosList.length} kos telah dipesan',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BookedKosListScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 32, thickness: 1),
              // Tombol lokasi
              ListTile(
                leading: const Icon(
                  Icons.map_outlined,
                  color: Colors.teal,
                  size: 35,
                ),
                title: const Text(
                  'Lokasi anda sekarang',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Maps untuk mencari lokasi anda dan kos yang telah dipesan',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullMapBookedKosScreen(
                        bookedKosList: accountProvider.bookedKosList,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 32, thickness: 1),

              // pengaturan notifikasi
              Text(
                'Pengaturan Notifikasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          _dailyReminderEnabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          color: _dailyReminderEnabled
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                              size: 35,
                        ),
                        title: const Text('Pengingat Harian Cek Aplikasi'),
                        subtitle: Text(
                          _dailyReminderEnabled
                              ? 'Aktif, setiap jam ${_selectedReminderTime?.format(context) ?? "09:00"}'
                              : 'Nonaktif',
                        ),
                        trailing: Switch(
                          value: _dailyReminderEnabled,
                          onChanged: (bool value) {
                            if (value && _selectedReminderTime == null) {
                              // Jika mengaktifkan dan waktu belum di-set, minta set waktu dulu
                              _selectReminderTime(context).then((_) {
                                // Jika setelah pilih waktu, _selectedReminderTime sudah ada, dan switch masih mau on
                                if (_selectedReminderTime != null) {
                                  _scheduleOrCancelDailyReminder(true);
                                } else {
                                  // User cancel time picker, matikan lagi switch nya
                                  setState(() => _dailyReminderEnabled = false);
                                  _saveReminderPreferences();
                                }
                              });
                            } else {
                              _scheduleOrCancelDailyReminder(value);
                            }
                          },
                        ),
                      ),
                      if (_dailyReminderEnabled) // Hanya tampilkan tombol ubah jika reminder aktif
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(
                                Icons.edit_calendar_outlined,
                                size: 20,
                              ),
                              label: const Text('Ubah Waktu Pengingat'),
                              onPressed: () => _selectReminderTime(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32, thickness: 1),

              // notif lain dari Youtube
              // ListTile(
              //   leading: const Icon(
              //     Icons.notification_important_outlined,
              //     color: Colors.red,
              //     size: 35,
              //   ),
              //   title: const Text(
              //     'Notif static anda',
              //     style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              //   ),
              //   subtitle: Text(
              //     'untuk menampilkan notif static',
              //   ),
              //   trailing: const Icon(Icons.chevron_right),
              //   onTap: () {
              //     // NotificationService.showInstantNotification(id: 0, title: 'Woke mase', body: "selamat datang");
              //     NotificationService.scheduleDailyReminderNotification(id: 0, title: 'Woke mase', body: "selamat datang", time: TimeOfDay.now());
              //   },
              // ),
              // review TPM
              // const Divider(height: 32, thickness: 1),
              ListTile(
                leading: const Icon(
                  Icons.school_outlined, // Atau Icons.rate_review_outlined
                  color: Colors.teal,
                  size: 35,
                ),
                title: const Text(
                  'Kesan & Saran Mata Kuliah',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Teknologi Mobile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const KesanSaranScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 32, thickness: 1),
            ],
          ),
        ),
      ),
    );
  }
}
