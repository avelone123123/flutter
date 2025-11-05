import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/screens/group/create_group_screen.dart';
import 'package:smart_attendance/screens/group/group_detail_screen.dart';
import 'package:smart_attendance/utils/auth_helper.dart';
import 'package:smart_attendance/models/group_model.dart';
import 'package:smart_attendance/services/web_group_service.dart';
import 'dart:async';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String get _currentUserId => AuthHelper.getCurrentUserId(context) ?? '';
  String _searchQuery = '';
  
  // Для веб - используем периодическое обновление
  List<GroupModel> _webGroups = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebGroups();
      // Автообновление каждые 5 секунд для веб
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _loadWebGroups();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWebGroups() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final webService = WebGroupService();
      final groups = await webService.getTeacherGroups(_currentUserId);
      if (mounted) {
        setState(() {
          _webGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWebGroups,
            ),
        ],
      ),
      body: kIsWeb ? _buildWebBody() : _buildMobileBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateGroup(),
        icon: const Icon(Icons.add),
        label: const Text('Создать группу'),
      ),
    );
  }

  // Веб-версия (REST API)
  Widget _buildWebBody() {
    if (_isLoading && _webGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWebGroups,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Фильтрация по поиску
    final filteredGroups = _webGroups.where((group) {
      final name = group.name.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Нет созданных групп'
                  : 'Группы не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Создайте первую группу'
                  : 'Попробуйте изменить запрос',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateGroup(),
                icon: const Icon(Icons.add),
                label: const Text('Создать группу'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWebGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGroups.length,
        itemBuilder: (context, index) {
          final group = filteredGroups[index];
          return _GroupCard(
            groupId: group.id,
            name: group.name,
            course: group.course,
            year: group.year,
            studentCount: group.studentIds.length,
            onTap: () => _navigateToGroupDetail(group.id),
          );
        },
      ),
    );
  }

  // Мобильная версия (Firebase Firestore)
  Widget _buildMobileBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('teacherId', isEqualTo: _currentUserId)
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data?.docs ?? [];

        // Фильтрация по поиску
        final filteredGroups = groups.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'Нет созданных групп'
                      : 'Группы не найдены',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Создайте первую группу'
                      : 'Попробуйте изменить запрос',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                if (_searchQuery.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateGroup(),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать группу'),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final doc = filteredGroups[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _GroupCard(
                groupId: doc.id,
                name: data['name'] ?? 'Без названия',
                course: data['course'] ?? '',
                year: data['year'] ?? 0,
                studentCount: (data['studentIds'] as List?)?.length ?? 0,
                onTap: () => _navigateToGroupDetail(doc.id),
              );
            },
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск группы'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите название группы',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    
    if (result == true && mounted) {
      if (kIsWeb) {
        _loadWebGroups();
      } else {
        setState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа успешно создана')),
      );
    }
  }

  void _navigateToGroupDetail(String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(groupId: groupId),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String groupId;
  final String name;
  final String course;
  final int year;
  final int studentCount;
  final VoidCallback onTap;

  const _GroupCard({
    required this.groupId,
    required this.name,
    required this.course,
    required this.year,
    required this.studentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.isNotEmpty) Text('Курс: $course'),
            Text('$year курс • $studentCount студентов'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
