
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/kyc_service.dart';

class OfficerKYCListScreen extends StatefulWidget {
  const OfficerKYCListScreen({super.key});

  @override
  State<OfficerKYCListScreen> createState() => _OfficerKYCListScreenState();
}

class _OfficerKYCListScreenState extends State<OfficerKYCListScreen> {
  late Future<List<Map<String, dynamic>>> _pendingKYCFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _pendingKYCFuture = KYCService.getPendingKYCRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบ KYC'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshList,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingKYCFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final pendingKYC = (snapshot.data != null && snapshot.data is List<Map<String, dynamic>>)
              ? snapshot.data!
              : <Map<String, dynamic>>[];

          if (pendingKYC.isEmpty) {
            return const Center(child: Text('ไม่มีรายการรอตรวจสอบ'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshList();
              await _pendingKYCFuture;
            },
            child: ListView.builder(
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
                    onTap: () async {
                      // รอผลกลับมาจากหน้า detail เพื่อ refresh รายการ
                      await context.push('/officer/kyc-detail/${item['memberid']}');
                      _refreshList();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
