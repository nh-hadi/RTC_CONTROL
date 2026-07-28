import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'services/esp_udp_service.dart';
import 'widgets/rtc_header.dart';
import 'widgets/wifi_settings_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RtcApp());
}

class RtcApp extends StatelessWidget {
  const RtcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDS-STORE RTC Controller',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F7FA), // Soft Light Blue-Grey
        colorScheme: const ColorScheme.light(
          primary: const Color(0xFF2C2493),
          secondary: const Color(0xFF06B6D4),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      home: const RtcHomeScreen(),
    );
  }
}

class RtcHomeScreen extends StatefulWidget {
  const RtcHomeScreen({super.key});

  @override
  State<RtcHomeScreen> createState() => _RtcHomeScreenState();
}

class _RtcHomeScreenState extends State<RtcHomeScreen> with TickerProviderStateMixin {
  final EspUdpService _udpService = EspUdpService();
  Timer? _localClockTimer;
  Timer? _blinkTimer;
  Timer? _toastTimer;
  Timer? _toastStartTimer;
  Timer? _toastClearTimer;
  DateTime _now = DateTime.now();
  late AnimationController _rgbAnimationController;
  late AnimationController _toastProgressController;
  bool _showColon = true;
  String? _toastMessage;
  bool _isToastSuccess = true;
  bool _showToast = false;

  @override
  void initState() {
    super.initState();
    _udpService.init();
    _localClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _showColon = !_showColon;
        });
      }
    });
    _rgbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Durasi 4 detik bolak-balik
    )..repeat(reverse: true);

    _toastProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Durasi loader menyusut tepat 3 detik
    );
  }

  @override
  void dispose() {
    _localClockTimer?.cancel();
    _blinkTimer?.cancel();
    _toastTimer?.cancel();
    _toastStartTimer?.cancel();
    _toastClearTimer?.cancel();
    _rgbAnimationController.dispose();
    _toastProgressController.dispose();
    super.dispose();
  }

  void _showCustomToast(String message, {bool isSuccess = true}) {
    // 1. Batalkan semua timer aktif dari klik sebelumnya agar tidak tumpang tindih
    _toastTimer?.cancel();
    _toastStartTimer?.cancel();
    _toastClearTimer?.cancel();

    // 2. Hentikan controller progress dan kembalikan nilainya ke 1.0 (penuh & diam)
    _toastProgressController.stop();
    _toastProgressController.value = 1.0;

    setState(() {
      _toastMessage = message;
      _isToastSuccess = isSuccess;
      _showToast = true; // Memicu transisi meluncur naik (300ms)
    });

    // 3. Jalankan loader menyusut setelah transisi meluncur naik selesai (300ms)
    _toastStartTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _showToast) {
        _toastProgressController.reverse(from: 1.0);
      }
    });

    // 4. Set timer penutupan pada 3300ms (300ms naik + 3000ms menyusut). Loader tepat menyentuh 0.0 (habis) saat slide-down dimulai
    _toastTimer = Timer(const Duration(milliseconds: 3300), () {
      if (mounted) {
        setState(() {
          _showToast = false; // Memicu transisi meluncur turun (300ms)
        });
        
        // 5. Tunggu 300ms transisi turun selesai, baru bersihkan data pesan agar widget aman hilang dari layout tree
        _toastClearTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && !_showToast) {
            setState(() {
              _toastMessage = null;
            });
          }
        });
      }
    });
  }

  String _getFormattedFullDate(DateTime now) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }



  Future<void> _openCustomDatePicker(BuildContext context) async {
    final isConnected = _udpService.connectionState.value == EspConnectionState.connected;
    if (!isConnected) {
      _showCustomToast('Waktu gagal diperbarui', isSuccess: false);
      return;
    }

    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2099),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF06B6D4),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF06B6D4),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null || !mounted) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      0,
    );

    _udpService.setRtcDateTime(
      selectedDateTime.year,
      selectedDateTime.month,
      selectedDateTime.day,
      selectedDateTime.hour,
      selectedDateTime.minute,
      selectedDateTime.second,
    );

    _showCustomToast('Waktu berhasil diperbarui');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAIN APP LAYOUT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3F7FA),
                  Color(0xFFE5ECF4),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ====================================================
                  RtcHeader(now: _now, udpService: _udpService),

                  // ====================================================
                  // MAIN BODY (RTC CLOCK & SENSOR METRICS)
                  // ====================================================
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          // DIGITAL CLOCK DISPLAY CARD
                          ValueListenableBuilder<RtcDataModel?>(
                            valueListenable: _udpService.rtcStateNotifier,
                            builder: (context, rtcData, _) {
                              return _buildMainClockCard(rtcData);
                            },
                          ),
                          const SizedBox(height: 20),

                          // HEALTH & METRIC GRID CARDS
                          ValueListenableBuilder<RtcDataModel?>(
                            valueListenable: _udpService.rtcStateNotifier,
                            builder: (context, rtcData, _) {
                              return _buildMetricsGrid(rtcData);
                            },
                          ),
                          const SizedBox(height: 24),

                          // ACTION BUTTONS (SYNC PHONE TIME & CUSTOM SET)
                          _buildActionButtons(context),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // OVERLAY TOAST / NOTIFICATION (Floating compact capsule with dynamic entry & exit animations)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack, // Efek memantul halus
            left: 24,
            right: 24,
            bottom: _showToast ? 35 : -140, // Turun lebih jauh agar tersembunyi sempurna saat keluar
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _showToast ? 1.0 : 0.0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240), // Lebih kompak
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24), // Membulat lebih premium
                      border: Border.all(
                        color: _isToastSuccess
                            ? const Color(0xFF10B981).withValues(alpha: 0.18)
                            : const Color(0xFFEF4444).withValues(alpha: 0.18),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C2493).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(22.8),
                        bottomRight: Radius.circular(22.8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bulatan Ikon Lembut
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: _isToastSuccess
                                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isToastSuccess ? Icons.check_rounded : Icons.close_rounded,
                                    color: _isToastSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _toastMessage ?? '',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2C2493),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Progress Bar Loader Kustom (Menyusut linear dari kanan ke kiri, terpotong rapi di dalam border melengkung)
                          AnimatedBuilder(
                            animation: _toastProgressController,
                            builder: (context, _) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _toastProgressController.value,
                                  child: Container(
                                    height: 3.5,
                                    color: _isToastSuccess
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // ULTRA-MODERN CENTER CLOCK DISPLAY CARD
  // ====================================================
  Widget _buildMainClockCard(RtcDataModel? rtcData) {
    final isValid = rtcData != null && rtcData.isValid;
    final hourStr = _now.hour.toString().padLeft(2, '0');
    final minuteStr = _now.minute.toString().padLeft(2, '0');
    final secondStr = _now.second.toString().padLeft(2, '0');
    
    // Tampilkan waktu RTC jika valid, jika tidak gunakan waktu HP (fallback) agar UI tetap menyala bagus
    final displayTime = isValid ? rtcData.formattedTime : '$hourStr:$minuteStr:$secondStr';
    final displayDate = isValid ? rtcData.fullFormattedDate : _getFormattedFullDate(_now);
    final dayOfWeekName = isValid ? rtcData.dayName.toUpperCase() : 'WAKTU LOKAL HP';

    // Pecah displayTime menjadi hh, mm, ss berdasarkan tanda ':' untuk segmentasi RGB
    final parts = displayTime.split(':');
    final hh = parts.isNotEmpty ? parts[0] : hourStr;
    final mm = parts.length > 1 ? parts[1] : minuteStr;
    final ss = parts.length > 2 ? parts[2] : secondStr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Border radius biasa
        border: Border.all(
          color: isValid
              ? const Color(0xFF2C2493).withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2493).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // TOP HEADER BADGES (DAY OF WEEK & SUHU & SOURCE)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge 1: Day of Week
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2493).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF2C2493).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF2C2493), size: 10),
                    const SizedBox(width: 4),
                    Text(
                      dayOfWeekName,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C2493),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge 2: Suhu (TCXO) - Gabung di display jam utama
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.thermostat_rounded,
                        color: Color(0xFFF59E0B), size: 10),
                    const SizedBox(width: 3),
                    Text(
                      rtcData != null ? '${rtcData.tempC.toStringAsFixed(1)} °C' : '-- °C',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isValid
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isValid
                        ? const Color(0xFF10B981)
                        : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                      size: 10,
                      color: isValid ? const Color(0xFF10B981) : Colors.orange,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isValid ? 'RTC ONLINE' : 'RTC OFFLINE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isValid ? const Color(0xFF10B981) : Colors.orange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // GIANT HIGH-TECH DIGITAL CLOCK DISPLAY (Running RGB Pelangi)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedBuilder(
              animation: _rgbAnimationController,
              builder: (context, _) {
                final double animVal = _rgbAnimationController.value;
                return ShaderMask(
                  shaderCallback: (bounds) {
                    // Geser koordinat X secara horizontal bolak-balik (ping-pong)
                    final double startX = animVal * 3.0 - 2.0;
                    final double endX = animVal * 3.0 - 0.5;
                    return LinearGradient(
                      colors: const [
                        Color(0xFFFF0055), // Red Neon
                        Color(0xFFFF9F00), // Orange
                        Color(0xFF00FF66), // Green Neon
                        Color(0xFF00F2FE), // Cyan
                        Color(0xFF00CCFF), // Blue Neon
                        Color(0xFFB900FF), // Violet
                        Color(0xFFFF0055), // Loop kembali ke Red
                      ],
                      begin: Alignment(startX, 0.0),
                      end: Alignment(endX, 0.0),
                    ).createShader(bounds);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        hh,
                        style: const TextStyle(
                          fontSize: 96, // ← DIPERBESAR LAGI
                          fontWeight: FontWeight.normal,
                          color: Colors.white, // Wajib putih agar ShaderMask bekerja
                          fontFamily: 'Digital7Mono',
                          letterSpacing: 0.0, // ← TIDAK JAUH-JAUH LAGI
                        ),
                      ),
                      Text(
                        _showColon ? ':' : ' ',
                        style: const TextStyle(
                          fontSize: 88,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontFamily: 'Digital7Mono',
                          height: 0.85,
                        ),
                      ),
                      Text(
                        mm,
                        style: const TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontFamily: 'Digital7Mono',
                          letterSpacing: 0.0,
                        ),
                      ),
                      Text(
                        _showColon ? ':' : ' ',
                        style: const TextStyle(
                          fontSize: 88,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontFamily: 'Digital7Mono',
                          height: 0.85,
                        ),
                      ),
                      Text(
                        ss,
                        style: const TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontFamily: 'Digital7Mono',
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // FULL DETAILED DATE DISPLAY
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FC),
              borderRadius: BorderRadius.circular(8), // Border radius biasa
              border: Border.all(
                color: const Color(0xFFE2E8F5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note_rounded,
                    color: Color(0xFF2C2493), size: 14),
                const SizedBox(width: 5),
                Text(
                  displayDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2C2493),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // METRICS & HEALTH GRID
  // ====================================================
  Widget _buildMetricsGrid(RtcDataModel? rtcData) {
    final isValid = rtcData?.isValid ?? false;
    final lostPower = rtcData?.lostPower ?? false;
    final errorCount = rtcData?.errorCount ?? 0;

    return Row(
      children: [
        // Card 1: Data Check
        Expanded(
          child: _buildMetricCard(
            title: 'VALIDITAS',
            value: isValid ? 'VALID' : 'INVALID',
            icon: isValid ? Icons.verified_rounded : Icons.gpp_bad_rounded,
            accentColor: isValid ? const Color(0xFF10B981) : Colors.red,
          ),
        ),
        const SizedBox(width: 8),

        // Card 2: Baterai
        Expanded(
          child: _buildMetricCard(
            title: 'BATERAI',
            value: lostPower ? 'OFF / DRAIN' : 'NORMAL',
            icon: lostPower ? Icons.battery_alert_rounded : Icons.battery_charging_full_rounded,
            accentColor: lostPower ? Colors.orange : const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: Glitch
        Expanded(
          child: _buildMetricCard(
            title: 'GLITCH',
            value: '$errorCount ERR',
            icon: Icons.bug_report_rounded,
            accentColor: errorCount == 0 ? const Color(0xFF2C2493) : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // Border radius biasa
        border: Border.all(
          color: const Color(0xFFE2E8F5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2493).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF525B75),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: accentColor, size: 12),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // ACTION BUTTONS: SYNC PHONE TIME & MANUAL SET
  // ====================================================
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // SYNC DEVICE TIME BUTTON
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C2493), Color(0xFF5B4CE0)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4CE0).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              final isConnected = _udpService.connectionState.value == EspConnectionState.connected;
              if (!isConnected) {
                _showCustomToast('Waktu gagal diperbarui', isSuccess: false);
                return;
              }
              _udpService.syncWithDeviceTime();
              _showCustomToast('Waktu berhasil diperbarui');
            },
            icon: const Icon(Icons.sync_rounded, size: 20, color: Colors.white),
            label: const Text(
              'Sinkronkan Waktu HP ke RTC',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // CUSTOM SET MANUAL BUTTON
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _openCustomDatePicker(context),
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text(
              'Set Waktu Manual',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2C2493),
              side: const BorderSide(color: Color(0xFF2C2493), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
