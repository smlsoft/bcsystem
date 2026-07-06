import 'package:intl/intl.dart';

void main() {
  // Test the new price formatting for large numbers
  final formatter = NumberFormat('#,###,##0.00', 'th_TH');
  
  List<double> testPrices = [
    99.99,        // หลักสิบ
    999.99,       // หลักร้อย
    9999.99,      // หลักพัน
    99999.99,     // หลักหมื่น
    999999.99,    // หลักแสน
    9999999.99,   // หลักล้าน
  ];
  
  print('=== Price Formatting Test ===');
  for (double price in testPrices) {
    String formatted = formatter.format(price);
    String digitsOnly = formatted.replaceAll(RegExp(r'[,.]'), '');
    int length = digitsOnly.length;
    
    double fontSize;
    if (length <= 4) {
      fontSize = 18.0;
    } else if (length <= 6) {
      fontSize = 16.0;
    } else if (length <= 8) {
      fontSize = 14.0;
    } else {
      fontSize = 12.0;
    }
    
    print('Price: $price -> Formatted: $formatted -> Font Size: $fontSize');
  }
}
