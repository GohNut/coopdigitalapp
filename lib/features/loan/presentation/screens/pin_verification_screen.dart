import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  String _pin = '';
  final int _pinLength = 6;

  void _onDigitPress(String digit) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += digit;
      });
      if (_pin.length == _pinLength) {
        _validatePin();
      }
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _validatePin() async {
    // Mock Validation
    await Future.delayed(const Duration(milliseconds: 500));
    if (_pin == '123456') {
      if (mounted) {
        context.go('/loan/success');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN ไม่ถูกต้อง'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary, // Use brand color for PIN screen often looks good
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'กรุณากรอกรหัส PIN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length ? Colors.white : Colors.white.withOpacity(0.3),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 64),
          
          // Numpad
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...List.generate(9, (index) => _buildNumBtn('${index + 1}')),
                  const SizedBox(), // Empty slot
                  _buildNumBtn('0'),
                  IconButton(
                    onPressed: _onDeletePress,
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),
             TextButton(
            onPressed: () {},
            child: const Text('ลืมรหัส PIN?', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String val) {
    return TextButton(
      onPressed: () => _onDigitPress(val),
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: Colors.white.withOpacity(0.1),
      ),
      child: Text(
        val,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
