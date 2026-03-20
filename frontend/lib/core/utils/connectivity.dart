import 'dart:async';
import 'dart:io';

class Net {
  static Future<bool> isOnline(String host, {int port = 80}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}