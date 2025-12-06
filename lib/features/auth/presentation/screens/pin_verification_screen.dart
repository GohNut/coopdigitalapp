import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  String _pin = '';
  final String _correctPin = '123456';
  bool _isError = false;

  void _onKeyPress(String value) {
    if (_pin.length < 6) {
      setState(() {
        _isError = false;
        _pin += value;
      });
      if (_pin.length == 6) {
        _validatePin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _isError = false;
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _validatePin() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_pin == _correctPin) {
      if (mounted) context.pop(true);
    } else {
      setState(() {
        _isError = true;
        _pin = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รหัส PIN ไม่ถูกต้อง กรุณาลองใหม่'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Blue background as per theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => context.pop(false),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          const Text(
            'กรุณากรอกรหัส PIN',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'เพื่อยืนยันตัวตน',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          
          const SizedBox(height: 48),
          
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isFilled ? Colors.white : Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: isFilled ? null : Border.all(color: Colors.white, width: 1.5),
                ),
              );
            }),
          ),
          
          if (_isError)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'รหัส PIN ไม่ถูกต้อง',
                style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
              ),
            ),
          
          const Spacer(),
          
          // Keypad
          Container(
            padding: const EdgeInsets.only(bottom: 48, top: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                _buildKeyRow(['4', '5', '6']),
                _buildKeyRow(['7', '8', '9']),
                _buildKeyRow(['', '0', 'del']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          if (key.isEmpty) return const SizedBox(width: 80, height: 80);
          if (key == 'del') {
            return _buildKeyButton(
              onTap: _onDelete,
              child: const Icon(LucideIcons.delete, color: Colors.black),
            );
          }
          return _buildKeyButton(
            onTap: () => _onKeyPress(key),
            child: Text(
              key,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyButton({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
