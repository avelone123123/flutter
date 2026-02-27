import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/web_group_service.dart';

class AddStudentsScreen extends StatefulWidget {
  final String groupId;

  const AddStudentsScreen({super.key, required this.groupId});

  @override
  State<AddStudentsScreen> createState() => _AddStudentsScreenState();
}

class _AddStudentsScreenState extends State<AddStudentsScreen> {
  final Set<String> _selectedStudentIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.addStudents ?? 'Добавить студентов'),
        actions: [
          if (_selectedStudentIds.isNotEmpty)
            TextButton.icon(
              onPressed: _isLoading ? null : _addStudents,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                '${localizations?.save ?? "Сохранить"} (${_selectedStudentIds.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: localizations?.searchStudents ?? 'Поиск студентов',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Список студентов
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _loadStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('${localizations?.error ?? "Ошибка"}: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!;
                final allStudents = data['allStudents'] as List<Map<String, dynamic>>;
                final currentStudentIds = data['currentStudentIds'] as Set<String>;

                // Фильтруем студентов, которых ещё нет в группе
                final availableStudents = allStudents
                    .where((student) => !currentStudentIds.contains(student['id']))
                    .where((student) {
                      if (_searchQuery.isEmpty) return true;
                      final name = student['name'].toString().toLowerCase();
                      final email = student['email'].toString().toLowerCase();
                      return name.contains(_searchQuery) || email.contains(_searchQuery);
                    })
                    .toList();

                if (availableStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Все студенты уже в группе'
                              : localizations?.noStudentsFound ?? 'Студенты не найдены',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableStudents.length,
                  itemBuilder: (context, index) {
                    final student = availableStudents[index];
                    final studentId = student['id'] as String;
                    final isSelected = _selectedStudentIds.contains(studentId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedStudentIds.add(studentId);
                            } else {
                              _selectedStudentIds.remove(studentId);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          child: Text(
                            student['name'].toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          student['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student['email']),
                            if (student['studentId'] != null)
                              Text(
                                'ID: ${student['studentId']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedStudentIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations?.selectedStudents ?? 'Выбрано студентов',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_selectedStudentIds.length} студентов',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addStudents,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(localizations?.save ?? 'Сохранить'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<Map<String, dynamic>> _loadStudents() async {
    if (kIsWeb) {
      try {
        final apiService = ApiService();
        final allStudentsList = await apiService.getAllStudents();
        final groupStudentsList = await apiService.getStudentsByGroup(widget.groupId);
        
        final currentStudentIds = groupStudentsList.map((s) => s['id'] as String).toSet();
        return {
          'allStudents': allStudentsList,
          'currentStudentIds': currentStudentIds,
        };
      } catch (e) {
        throw Exception('Ошибка загрузки студентов: $e');
      }
    }
    
    try {
      // Получить текущих студентов группы
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      final currentStudentIds = Set<String>.from(groupDoc.data()?['studentIds'] ?? []);

      // Получить всех пользователей с ролью student
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final allStudents = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Студент',
          'email': data['email'] ?? '',
          'studentId': data['studentId'],
        };
      }).toList();

      // Сортировка по имени
      allStudents.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      return {
        'allStudents': allStudents,
        'currentStudentIds': currentStudentIds,
      };
    } catch (e) {
      throw Exception('Ошибка загрузки студентов: $e');
    }
  }

  Future<void> _addStudents() async {
    if (_selectedStudentIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        final webGroupService = WebGroupService();
        for (final studentId in _selectedStudentIds) {
          await webGroupService.addStudentToGroup(widget.groupId, studentId);
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }
      
      // Получить текущий список студентов
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      final currentStudents = List<String>.from(groupDoc.data()?['studentIds'] ?? []);

      // Добавить новых студентов
      currentStudents.addAll(_selectedStudentIds);

      // Обновить группу
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'studentIds': currentStudents});

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations?.error ?? "Ошибка"}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
