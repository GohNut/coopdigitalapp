import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final int maxDecimalDigits;

  CurrencyInputFormatter({this.maxDecimalDigits = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle deletion
    if (oldValue.text.length > newValue.text.length) {
       // Allow standard backspace behavior, but we might need to reformat if it messes up commas
       // For simple cases, let's just reformat the remaining raw number
    }

    // 1. Remove all non-numeric characters except dot
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // Prevent multiple dots
    if ('.'.allMatches(newText).length > 1) {
      // If adding a second dot, revert to old value
      return oldValue;
    }

    // Handle text starting with dot
    if (newText.startsWith('.')) {
      newText = '0$newText';
    }
    
    // Split into integer and decimal parts
    List<String> parts = newText.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Limit decimal digits
    if (decimalPart != null && decimalPart.length > maxDecimalDigits) {
       decimalPart = decimalPart.substring(0, maxDecimalDigits);
    }
    
    // Format integer part with commas
    if (integerPart.isNotEmpty) {
      final  formatter = NumberFormat("#,###");
      try {
          // If the integer part is just "0" and we have decimals, keep "0"
          // If it's leading zeros like "05", parse it to "5"
         if (integerPart != '0' || decimalPart == null) {
            integerPart = formatter.format(int.parse(integerPart));
         }
      } catch (e) {
        // Fallback or ignore
      }
    }

    // Reassemble
    String formattedText = integerPart;
    if (parts.length > 1 || newValue.text.endsWith('.')) {
      formattedText += '.';
      if (decimalPart != null) {
        formattedText += decimalPart;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
