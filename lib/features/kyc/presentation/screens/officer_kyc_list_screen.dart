
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/kyc_service.dart';

class OfficerKYCListScreen extends StatelessWidget {
  const OfficerKYCListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบ KYC'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: KYCService.getPendingKYCRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final pendingKYC = snapshot.data ?? [];

          if (pendingKYC.isEmpty) {
            return const Center(child: Text('ไม่มีรายการรอตรวจสอบ'));
          }

          return ListView.builder(
            itemCount: pendingKYC.length,
            itemBuilder: (context, index) {
              final item = pendingKYC[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(LucideIcons.user, color: Colors.white),
                  ),
                  title: Text(item['name_th'] ?? 'Unknown'),
                  subtitle: Text('ID: ${item['memberid']}'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    context.push('/officer/kyc-detail/${item['memberid']}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
