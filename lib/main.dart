import 'dart:async';
import 'package:flutter/material.dart';
import 'services/esp_udp_service.dart';

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
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Slate Navy
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // Cyan Accent
          secondary: Color(0xFF3B82F6), // Blue Accent
          surface: Color(0xFF1E293B), // Card Surface
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

class _RtcHomeScreenState extends State<RtcHomeScreen> {
  final EspUdpService _udpService = EspUdpService();
  Timer? _localClockTimer;
  DateTime _now = DateTime.now();

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
  }

  @override
  void dispose() {
    _localClockTimer?.cancel();
    super.dispose();
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

  void _openWifiSettingsDialog(BuildContext context) {
    final TextEditingController ipController =
        TextEditingController(text: _udpService.currentTargetIp);
    bool isTesting = false;
    String? testResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Color(0xFF06B6D4), width: 1.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_rounded,
                            color: Color(0xFF06B6D4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengaturan Koneksi WiFi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Konfigurasi IP Target ESP UDP (Default: 192.168.4.1)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: ipController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Alamat IP ESP32 / ESP8266',
                        labelStyle: const TextStyle(color: Color(0xFF06B6D4)),
                        prefixIcon: const Icon(Icons.router, color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF06B6D4)),
                        ),
                      ),
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: testResult!.contains('Berhasil')
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: testResult!.contains('Berhasil')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              testResult!.contains('Berhasil')
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: testResult!.contains('Berhasil')
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: TextStyle(
                                  color: testResult!.contains('Berhasil')
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isTesting
                                ? null
                                : () async {
                                    setModalState(() {
                                      isTesting = true;
                                      testResult = null;
                                    });
                                    final ok = await _udpService
                                        .testConnection(ipController.text);
                                    setModalState(() {
                                      isTesting = false;
                                      testResult = ok
                                          ? 'Berhasil terhubung ke ESP!'
                                          : 'Gagal terhubung ke IP tersebut!';
                                    });
                                  },
                            icon: isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF06B6D4),
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded),
                            label: const Text('Tes Koneksi'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF06B6D4),
                              side: const BorderSide(color: Color(0xFF06B6D4)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _udpService.updateTargetIp(ipController.text);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Target IP diperbarui ke ${ipController.text}'),
                                  backgroundColor: const Color(0xFF06B6D4),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Simpan IP',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCustomDatePicker(BuildContext context) async {
    final now = DateTime.now();
    // Capture messenger before async gap to avoid BuildContext warning
    final messenger = ScaffoldMessenger.of(context);

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

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Waktu diset ke ${selectedDateTime.toString().split('.')[0]}',
        ),
        backgroundColor: const Color(0xFF06B6D4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1329),
              Color(0xFF0F172A),
              Color(0xFF040914),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ====================================================
              // MODERN HEADER WITH BRANDING & WIFI BUTTON
              // ====================================================
              _buildHeader(context),

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
    );
  }

  // ====================================================
  // HEADER: LIGHT BACKGROUND, SINGLE ROW (IDS-STORE | DATE+TIME PILLS | WIFI)
  // ====================================================
  Widget _buildHeader(BuildContext context) {
    final hour   = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final timeStr = '$hour : $minute : $second';
    final dateStr = _getFormattedFullDate(_now);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── LEFT: IDS-STORE ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2493),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text(
                  'IDS-STORE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ),

          // ── CENTER: DATE + TIME PILLS ─────────────────────
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // DATE CAPSULE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF3B3A98),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Color(0xFF3B3A98),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // TIME CAPSULE
                Container(
                  padding: const EdgeInsets.fromLTRB(7, 6, 13, 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2493), Color(0xFF5B4CE0)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4CE0).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.access_time_filled_rounded,
                            color: Color(0xFF2C2493),
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.6,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── RIGHT: STATUS DOT + WIFI BUTTON ──────────────
          ValueListenableBuilder<EspConnectionState>(
            valueListenable: _udpService.connectionState,
            builder: (context, state, _) {
              final isConnected = state == EspConnectionState.connected;
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withOpacity(0.7),
                      blurRadius: 6,
                    ),
                  ],
                ),
              );
            },
          ),

          GestureDetector(
            onTap: () => _openWifiSettingsDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.nightlight_round,
                  color: Color(0xFF525B75),
                  size: 17,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E293B).withOpacity(0.95),
            const Color(0xFF0F172A).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isValid
              ? const Color(0xFF00F2FE).withOpacity(0.4)
              : Colors.redAccent.withOpacity(0.4),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isValid
                ? const Color(0xFF00F2FE).withOpacity(0.15)
                : Colors.redAccent.withOpacity(0.15),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // TOP HEADER BADGES (DAY OF WEEK & SOURCE)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF06B6D4).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF00F2FE), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      rtcData?.dayName.toUpperCase() ?? 'DS3231 HARDWARE',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00F2FE),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isValid
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isValid
                        ? const Color(0xFF10B981)
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                      size: 14,
                      color: isValid ? const Color(0xFF34D399) : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isValid ? 'RTC REALTIME' : 'WAITING DEVICE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isValid ? const Color(0xFF34D399) : Colors.orangeAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // GIANT HIGH-TECH NEON DIGITAL CLOCK DISPLAY
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rtcData?.formattedTime ?? '--:--:--',
              style: TextStyle(
                fontSize: 62,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 4.0,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.7),
                    blurRadius: 20,
                  ),
                  Shadow(
                    color: const Color(0xFF4FACFE).withOpacity(0.5),
                    blurRadius: 35,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // FULL DETAILED DATE DISPLAY ("Senin, 27 Juli 2026")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note_rounded,
                    color: Color(0xFF06B6D4), size: 18),
                const SizedBox(width: 8),
                Text(
                  rtcData != null && rtcData.isValid
                      ? rtcData.fullFormattedDate
                      : 'Tanggal Belum Terhubung',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // HARDWARE CHIP SUBTITLE STATUS
          Text(
            isValid
                ? '⚡ Membaca langsung dari Chip DS3231 (TCXO Accuracy ±2ppm)'
                : '⚠️ Periksa koneksi WiFi UDP ke ESP32/ESP8266',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isValid ? const Color(0xFF06B6D4) : Colors.redAccent,
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
    final tempStr = rtcData != null ? '${rtcData.tempC.toStringAsFixed(2)} °C' : '-- °C';
    final isValid = rtcData?.isValid ?? false;
    final lostPower = rtcData?.lostPower ?? false;
    final errorCount = rtcData?.errorCount ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: [
        // TEMPERATURE CARD
        _buildMetricCard(
          title: 'Suhu Chip RTC',
          value: tempStr,
          icon: Icons.thermostat_rounded,
          accentColor: const Color(0xFFF59E0B),
          statusText: 'Sensor TCXO Internal',
        ),

        // VALIDITY CARD
        _buildMetricCard(
          title: 'Validitas Data',
          value: isValid ? 'VALID' : 'INVALID',
          icon: isValid ? Icons.verified_rounded : Icons.gpp_bad_rounded,
          accentColor: isValid ? Colors.green : Colors.red,
          statusText: isValid ? 'Sanity Check Lolos' : 'Glitch I2C / Error',
        ),

        // POWER STATUS CARD
        _buildMetricCard(
          title: 'Status Baterai',
          value: lostPower ? 'POWER LOST' : 'POWER OK',
          icon: lostPower ? Icons.battery_alert_rounded : Icons.battery_charging_full_rounded,
          accentColor: lostPower ? Colors.orange : Colors.green,
          statusText: lostPower ? 'Bit OSF = 1 (Lepas)' : 'Osilator RTC Normal',
        ),

        // ERROR COUNTER CARD
        _buildMetricCard(
          title: 'Glitch Count',
          value: '$errorCount Error',
          icon: Icons.bug_report_rounded,
          accentColor: errorCount == 0 ? const Color(0xFF3B82F6) : Colors.red,
          statusText: 'Akumulasi Read Retry',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String statusText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white38,
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
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              _udpService.syncWithDeviceTime();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Sinyal Sync Waktu HP dikirim via UDP!'),
                  backgroundColor: Color(0xFF06B6D4),
                ),
              );
            },
            icon: const Icon(Icons.sync_rounded, size: 22),
            label: const Text(
              'Sinkronkan Waktu HP ke RTC',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.black,
              elevation: 4,
              shadowColor: const Color(0xFF06B6D4).withOpacity(0.4),
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
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _openCustomDatePicker(context),
            icon: const Icon(Icons.edit_calendar_rounded, size: 20),
            label: const Text(
              'Set Waktu Manual',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF06B6D4),
              side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
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
