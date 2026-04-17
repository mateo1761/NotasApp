import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class Net {
  static Future<bool> isOnline(String host, {int port = 80}) async {
    debugPrint('Net.isOnline: Checking $host:$port');
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      debugPrint('Net.isOnline: Connection successful to $host:$port');
      socket.destroy();
      return true;
    } catch (e) {
      debugPrint('Net.isOnline: Connection failed to $host:$port - $e');
      return false;
    }
  }
}