import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class PinSetupScreen extends StatefulWidget {
  final Future<void> Function(String) onPinSet;

  const PinSetupScreen({super.key, required this.onPinSet});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isError = false;
  bool _isLoading = false;
  String _errorMessage = '';

  void _onKeyPress(String value) {
    if (_isLoading) return;
    setState(() {
      _isError = false;
      _errorMessage = '';
      if (!_isConfirming) {
        if (_pin.length < 6) _pin += value;
        if (_pin.length == 6) {
          _isConfirming = true;
        }
      } else {
        if (_confirmPin.length < 6) _confirmPin += value;
        if (_confirmPin.length == 6) {
          _validatePin();
        }
      }
    });
  }

  void _onDelete() {
    if (_isLoading) return;
    setState(() {
      _isError = false;
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Back to first step
          _isConfirming = false;
          _pin = '';
        }
      }
    });
  }

  Future<void> _validatePin() async {
    if (_pin == _confirmPin) {
      setState(() => _isLoading = true);
      try {
        await widget.onPinSet(_pin);
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = e.toString();
          _confirmPin = '';
          _pin = '';
          _isConfirming = false;
        });
      }
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'รหัส PIN ไม่ตรงกัน กรุณาลองใหม่';
        _confirmPin = '';
        _pin = ''; // Optional: Clear both or just confirm? Usually assume type error in confirm, but safe to clear confirm. 
                   // Let's clear confirm first or reset both??
                   // Let's reset confirm only first, but UX might be better if we reset confirm and let them try again.
        _isConfirming = false; // Reset to start
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () {
            if (_isConfirming) {
              setState(() {
                _isConfirming = false;
                _confirmPin = '';
                _pin = '';
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            _isConfirming ? 'ยืนยันรหัส PIN' : 'ตั้งรหัส PIN',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            _isConfirming ? 'กรอกรหัส PIN อีกครั้ง' : 'สร้างรหัส PIN 6 หลักเพื่อใช้งาน',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          
          const SizedBox(height: 48),
          
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final code = _isConfirming ? _confirmPin : _pin;
              final isFilled = index < code.length;
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
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(color: Colors.white),
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
