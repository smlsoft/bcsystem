import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

Future<void> connectivity() async {
  final result = await (Connectivity().checkConnectivity());
  if (result.isNotEmpty) {
    switch (result[0]) {
      case ConnectivityResult.none:
        AppLogger.debug("I am disconnected.");
        break;
      case ConnectivityResult.mobile:
        AppLogger.debug("I am connected to a mobile network.");
        break;
      case ConnectivityResult.wifi:
        AppLogger.debug("I am connected to a wifi network.");
        break;
      case ConnectivityResult.ethernet:
        AppLogger.debug("I am connected to a ethernet network.");
        break;
      case ConnectivityResult.bluetooth:
        break;
      case ConnectivityResult.vpn:
        break;
      case ConnectivityResult.other:
        break;
    }
  }
}

bool _isPrivateIpv4Address(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return false;

  final octets = parts.map((part) => int.tryParse(part)).toList();
  if (octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
    return false;
  }

  final first = octets[0]!;
  final second = octets[1]!;
  return first == 10 || (first == 172 && second >= 16 && second <= 31) || (first == 192 && second == 168);
}

Future<String> ipAddress() async {
  // Get a list of the network interfaces available on the device
  List<NetworkInterface> interfaces = await NetworkInterface.list();

  // Iterate through the list of interfaces and return the first non-loopback IPv4 address
  for (NetworkInterface interface in interfaces) {
    if (interface.name == 'lo') continue; // Skip the loopback interface
    for (InternetAddress address in interface.addresses) {
      if (_isPrivateIpv4Address(address.address) && address.type == InternetAddressType.IPv4) {
        return address.address;
      }
    }
  }

  // If no non-loopback IPv4 address was found, return null
  return "";
}
