// lib/utils/converters.dart
import 'package:fixnum/fixnum.dart';
import 'constants.dart';

class WartConverter {
  // Konverto WART në E8 (Int64)
  static Int64 wartToE8(double wart) {
    return Int64((wart * WarthogConstants.e8Multiplier).round());
  }
  
  // Konverto E8 në WART (double)
  static double e8ToWart(Int64 e8) {
    return e8.toDouble() / WarthogConstants.e8Multiplier;
  }
  
  // Konverto E8 në WART (int)
  static double e8ToWartInt(int e8) {
    return e8 / WarthogConstants.e8Multiplier;
  }
  
  // Format balancën për UI
  static String formatBalance(double balance) {
    return balance.toStringAsFixed(4);
  }
  
  // Format adresën për display (shkurto)
  static String formatAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }
}