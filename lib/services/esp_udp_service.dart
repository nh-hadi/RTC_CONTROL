import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

enum EspConnectionState { disconnected, connecting, connected }

class RtcDataModel {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final int dayOfWeek;
  final double tempC;
  final bool isValid;
  final bool lostPower;
  final int errorCount;

  RtcDataModel({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.dayOfWeek,
    required this.tempC,
    required this.isValid,
    required this.lostPower,
    required this.errorCount,
  });

  String get formattedDate {
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    return '$d / $m / $year';
  }

  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get dayName {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    if (dayOfWeek >= 0 && dayOfWeek < days.length) {
      return days[dayOfWeek];
    }
    return '?';
  }

  String get monthName {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  String get fullFormattedDate {
    final d = day.toString().padLeft(2, '0');
    return '$dayName, $d $monthName $year';
  }
}

class EspUdpService {
  static final EspUdpService _instance = EspUdpService._internal();
  factory EspUdpService() => _instance;
  EspUdpService._internal();

  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;

  DateTime _lastResponseTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Timeout: 6 detik tidak ada response -> disconnected
  static const Duration _connectionTimeout = Duration(seconds: 6);
  static const Duration _heartbeatInterval = Duration(seconds: 1);

  final ValueNotifier<EspConnectionState> connectionState =
      ValueNotifier<EspConnectionState>(EspConnectionState.disconnected);

  final ValueNotifier<RtcDataModel?> rtcStateNotifier =
      ValueNotifier<RtcDataModel?>(null);

  String _espIp = '192.168.4.1';
  static const int _espPort = 8888;

  String get currentTargetIp => _espIp;

  void updateTargetIp(String newIp) {
    if (newIp.trim().isNotEmpty) {
      _espIp = newIp.trim();
      queryState();
    }
  }

  void init() async {
    if (_socket != null) {
      try {
        _socket!.send(const [], InternetAddress.anyIPv4, 0);
        return;
      } catch (_) {
        _socket?.close();
        _socket = null;
      }
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = false;

      _socket?.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null) {
              final message = String.fromCharCodes(datagram.data).trim();
              if (message.startsWith('RTC:')) {
                _handleRtcResponse(message);
              }
            }
          }
        },
        onError: (e) {
          debugPrint('UDP Socket Error: $e');
          _socket?.close();
          _socket = null;
          connectionState.value = EspConnectionState.disconnected;
        },
        onDone: () {
          _socket = null;
          connectionState.value = EspConnectionState.disconnected;
        },
        cancelOnError: true,
      );

      _startHeartbeat();
      debugPrint('UDP Socket RTC Berhasil Diinisialisasi.');
    } catch (e) {
      debugPrint('UDP Bind Error: $e');
      _socket = null;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    queryState();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _checkConnectionTimeout();
      queryState();
    });
  }

  void _checkConnectionTimeout() {
    if (connectionState.value == EspConnectionState.connected) {
      final elapsed = DateTime.now().difference(_lastResponseTime);
      if (elapsed > _connectionTimeout) {
        connectionState.value = EspConnectionState.disconnected;
      }
    }
  }

  void queryState() {
    _send('Q');
  }

  Future<bool> testConnection(String testIp) async {
    final Completer<bool> completer = Completer<bool>();
    RawDatagramSocket? testSocket;

    try {
      testSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      testSocket.broadcastEnabled = false;

      Timer? timeoutTimer;

      testSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = testSocket?.receive();
          if (datagram != null) {
            final msg = String.fromCharCodes(datagram.data).trim();
            if (msg.startsWith('RTC:')) {
              if (!completer.isCompleted) {
                timeoutTimer?.cancel();
                _handleRtcResponse(msg);
                completer.complete(true);
              }
            }
          }
        }
      });

      final data = 'Q'.codeUnits;
      testSocket.send(data, InternetAddress(testIp.trim()), _espPort);

      timeoutTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!completer.isCompleted) completer.complete(false);
      });
    } catch (e) {
      if (!completer.isCompleted) completer.complete(false);
    } finally {
      Timer(const Duration(milliseconds: 2000), () {
        testSocket?.close();
      });
    }

    return completer.future;
  }

  void _handleRtcResponse(String message) {
    // Format: RTC:YYYY,MM,DD,HH,MM,SS,DayOfWeek,TempC,Valid,LostPower,ErrorCount
    try {
      final parts = message.substring(4).split(',');
      if (parts.length >= 11) {
        _lastResponseTime = DateTime.now();
        connectionState.value = EspConnectionState.connected;

        rtcStateNotifier.value = RtcDataModel(
          year: int.parse(parts[0]),
          month: int.parse(parts[1]),
          day: int.parse(parts[2]),
          hour: int.parse(parts[3]),
          minute: int.parse(parts[4]),
          second: int.parse(parts[5]),
          dayOfWeek: int.parse(parts[6]),
          tempC: double.parse(parts[7]),
          isValid: parts[8] == '1',
          lostPower: parts[9] == '1',
          errorCount: int.parse(parts[10]),
        );
      }
    } catch (e) {
      debugPrint('Error Parse RTC UDP: $e');
    }
  }

  void _send(String message) {
    if (_socket == null) {
      init();
      return;
    }
    try {
      _socket?.send(message.codeUnits, InternetAddress(_espIp), _espPort);
    } catch (e) {
      debugPrint('UDP Send Error: $e');
      _socket?.close();
      _socket = null;
      connectionState.value = EspConnectionState.disconnected;
    }
  }

  void setRtcDateTime(int y, int m, int d, int h, int min, int s) {
    _send('SET:$y,$m,$d,$h,$min,$s');
  }

  void syncWithDeviceTime() {
    final now = DateTime.now();
    setRtcDateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
  }

  void setRtcUnix(int epoch) {
    _send('UNIX:$epoch');
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
