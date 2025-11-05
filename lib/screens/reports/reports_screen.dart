import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/auth_helper.dart';
import 'group_report_screen.dart';
import 'subject_report_screen.dart';
import 'detailed_stats_screen.dart';

/// Экран отчётов и статистики
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Загружаем данные после первого фрейма
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Загрузка данных
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teacherId = AuthHelper.getCurrentUserId(context);

      if (teacherId != null) {
        // Данные загружаются напрямую в дочерних экранах через StreamBuilder
        // Здесь просто симулируем небольшую задержку для UX
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных отчетов: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчёты и статистика'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.group),
              text: 'По группам',
            ),
            Tab(
              icon: Icon(Icons.subject),
              text: 'По предметам',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Детальная статистика',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: const [
                GroupReportScreen(),
                SubjectReportScreen(),
                DetailedStatsScreen(),
              ],
            ),
    );
  }
}
