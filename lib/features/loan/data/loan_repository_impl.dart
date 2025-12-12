import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/loan_repository.dart';
import '../domain/loan_application_model.dart';
import '../domain/loan_product_model.dart';

class LoanRepositoryImpl implements LoanRepository {
  @override
  Future<void> submitApplication({
    required String productId,
    required double amount,
    required int months,
    String? guarantorId,
    String? objective,
  }) async {
    // Mock implementation for now
    await Future.delayed(const Duration(seconds: 1));
    return;
  }

  @override
  Future<List<LoanApplication>> getLoanApplications() async {
    try {
      final String response = await rootBundle.loadString('assets/mock_data/loan_applications.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => LoanApplication.fromJson(json)).toList();
    } catch (e) {
      print('Error loading loan applications: $e');
      return [];
    }
  }

  @override
  Future<List<LoanProduct>> getLoanProducts() async {
    try {
      final String response = await rootBundle.loadString('assets/mock_data/loan_products.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => LoanProduct.fromJson(json)).toList();
    } catch (e) {
      print('Error loading loan products: $e');
      return [];
    }
  }
}
