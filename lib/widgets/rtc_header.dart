import 'package:flutter/material.dart';
import '../services/esp_udp_service.dart';
import 'wifi_settings_dialog.dart';

class RtcHeader extends StatelessWidget {
  final DateTime now;
  final EspUdpService udpService;

  const RtcHeader({
    super.key,
    required this.now,
    required this.udpService,
  });

  String _getFormattedFullDate(DateTime dateTime) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[dateTime.weekday % 7];
    final monthName = months[dateTime.month];
    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hour   = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute:$second';
    final dateStr = _getFormattedFullDate(now);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Skala berdasarkan lebar layar (referensi: 360px)
        final w = constraints.maxWidth;
        final scale = (w / 360).clamp(0.72, 1.0);

        final badgePadH  = 10.0 * scale;
        final badgePadV  = 5.0 * scale;
        final pillPadH   = 10.0 * scale;
        final pillPadV   = 5.0 * scale;
        final iconSz     = 12.0 * scale;
        final dateFontSz = 11.0 * scale;
        final timeFontSz = 11.0 * scale;
        final brandFontSz = 10.0 * scale;
        final gap        = 6.0 * scale;

        return Container(
          margin: EdgeInsets.fromLTRB(12, 10 * scale, 12, 0),
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FC), // Warna terang (Light Theme)
            borderRadius: BorderRadius.circular(30), // Kapsul membulat penuh
            border: Border.all(color: const Color(0xFFE2E8F5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── KIRI: IDS-STORE ─────────────────────────────
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: badgePadH, vertical: badgePadV),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2493),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: iconSz),
                      SizedBox(width: 3 * scale),
                      Text(
                        'IDS-STORE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: brandFontSz,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: gap),

              // ── TENGAH: DATE + TIME PILLS (FittedBox auto-scale) ─
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // DATE PILL
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: pillPadH, vertical: pillPadV),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: const Color(0xFF3B3A98),
                              size: iconSz,
                            ),
                            SizedBox(width: 4 * scale),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: const Color(0xFF3B3A98),
                                fontWeight: FontWeight.w700,
                                fontSize: dateFontSz,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: gap),

                      // TIME PILL (purple gradient)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: pillPadH, vertical: pillPadV),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C2493), Color(0xFF5B4CE0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              color: Colors.white,
                              size: iconSz,
                            ),
                            SizedBox(width: 5 * scale),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: timeFontSz,
                                letterSpacing: 0.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: gap),

              // ── KANAN: STATUS DOT + WIFI BUTTON ─────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ValueListenableBuilder<EspConnectionState>(
                    valueListenable: udpService.connectionState,
                    builder: (context, state, _) {
                      final isConnected = state == EspConnectionState.connected;
                      return Container(
                        width: 7 * scale,
                        height: 7 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 5 * scale),
                  GestureDetector(
                    onTap: () => openWifiSettingsDialog(context, udpService),
                    child: Container(
                      padding: EdgeInsets.all(5 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0), width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.wifi_rounded,
                          color: const Color(0xFF525B75),
                          size: 14 * scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
