import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';
import 'steps/step_1_account_screen.dart';
import 'steps/step_2_personal_info_screen.dart';
import 'steps/step_3_occupation_screen.dart';
import 'steps/step_4_consent_screen.dart';

class RegisterWizardScreen extends ConsumerWidget {
  const RegisterWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียนสมาชิก'),
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: notifier.prevStep,
              )
            : null, // Allow default back button on first step to exit
      ),
      body: Column(
        children: [
          _buildStepper(state.currentStep),
          Expanded(
            child: _buildStepContent(state.currentStep),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(int currentStep) {
    // Simple progress indicator
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          _buildStepIcon(0, currentStep, 'บัญชี'),
          _buildConnector(0, currentStep),
          _buildStepIcon(1, currentStep, 'ข้อมูลส่วนตัว'),
          _buildConnector(1, currentStep),
          _buildStepIcon(2, currentStep, 'อาชีพ'),
          _buildConnector(2, currentStep),
          _buildStepIcon(3, currentStep, 'ยืนยัน'),
        ],
      ),
    );
  }

  Widget _buildStepIcon(int stepIndex, int currentStep, String label) {
    final isActive = stepIndex == currentStep;
    final isCompleted = stepIndex < currentStep;

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isActive
                ? Colors.blue
                : isCompleted
                    ? Colors.green
                    : Colors.grey,
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.blue : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int stepIndex, int currentStep) {
    if (stepIndex >= 3) return const SizedBox.shrink();
    return Expanded(
      child: Container(
        height: 2,
        color: stepIndex < currentStep ? Colors.green : Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14), // Adjust alignment
      ),
    );
  }

  Widget _buildStepContent(int currentStep) {
    switch (currentStep) {
      case 0:
        return const Step1AccountScreen();
      case 1:
        return const Step2PersonalInfoScreen();
      case 2:
        return const Step3OccupationScreen();
      case 3:
        return const Step4ConsentScreen();
      default:
        return const Center(child: Text('Unknown Step'));
    }
  }
}
