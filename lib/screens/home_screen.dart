import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/router.dart';
import '../widgets/auth_consumer.dart';
import '../services/api_service.dart';
import 'group/groups_screen.dart';
import 'lesson/lessons_screen.dart';
import 'reports/reports_screen.dart';
import 'profile_screen.dart';
import 'group/create_group_screen.dart';
import 'lesson/create_lesson_screen.dart';
import 'lesson/active_lessons_screen.dart';

/// Главный экран приложения
/// Показывает разный интерфейс для преподавателей и студентов
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AuthConsumer(
      builder: (context, authProvider, child) {
        final providerData = AuthProviderData.from(authProvider);
        if (providerData.userRole == UserRole.teacher) {
          return _buildTeacherHome();
        } else {
          return _buildStudentHome();
        }
      },
    );
  }

  /// Главный экран для преподавателя
  Widget _buildTeacherHome() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance'),
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return IconButton(
                icon: Text(localeProvider.countryFlag),
                onPressed: () {
                  localeProvider.toggleLanguage();
                },
                tooltip: 'Переключить язык',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Показать уведомления
            },
          ),
        ],
      ),
      body: _getTeacherBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Группы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Занятия',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  /// Главный экран для студента
  Widget _buildStudentHome() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance'),
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return IconButton(
                icon: Text(localeProvider.countryFlag),
                onPressed: () {
                  localeProvider.toggleLanguage();
                },
                tooltip: 'Переключить язык',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Показать уведомления
            },
          ),
        ],
      ),
      body: _getStudentBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QR Сканер',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Расписание',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  /// Тело экрана для преподавателя
  Widget _getTeacherBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildTeacherDashboard();
      case 1:
        return const GroupsScreen();
      case 2:
        return const LessonsScreen();
      case 3:
        return const ReportsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildTeacherDashboard();
    }
  }

  /// Тело экрана для студента
  Widget _getStudentBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildStudentDashboard();
      case 1:
        return _buildQRScanner();
      case 2:
        return _buildStudentSchedule();
      case 3:
        return _buildStudentStatistics();
      case 4:
        return const ProfileScreen();
      default:
        return _buildStudentDashboard();
    }
  }

  /// Дашборд преподавателя
  Widget _buildTeacherDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветствие
          AuthConsumer(
            builder: (context, authProvider, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Добро пожаловать, ${authProvider.userName}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Управляйте группами и отслеживайте посещаемость студентов',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Быстрые действия
          Text(
            'Быстрые действия',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildQuickActionCard(
                icon: Icons.add,
                title: 'Создать группу',
                subtitle: 'Добавить новую группу студентов',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.schedule,
                title: 'Новое занятие',
                subtitle: 'Запланировать занятие',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateLessonScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.qr_code,
                title: 'QR-код',
                subtitle: 'Активные занятия',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ActiveLessonsScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.analytics,
                title: 'Отчеты',
                subtitle: 'Просмотр статистики',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Статистика
          Text(
            'Статистика',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Всего групп',
                  value: '0',
                  icon: Icons.groups,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Всего студентов',
                  value: '0',
                  icon: Icons.people,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Дашборд студента
  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветствие
          AuthConsumer(
            builder: (context, authProvider, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Привет, ${authProvider.userName}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Отмечайте посещаемость и следите за своим прогрессом',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Быстрые действия
          Text(
            'Быстрые действия',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildQuickActionCard(
                icon: Icons.qr_code_scanner,
                title: 'Сканировать QR',
                subtitle: 'Отметить посещаемость',
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _buildQuickActionCard(
                icon: Icons.schedule,
                title: 'Расписание',
                subtitle: 'Мои занятия',
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              _buildQuickActionCard(
                icon: Icons.analytics,
                title: 'Статистика',
                subtitle: 'Моя посещаемость',
                onTap: () {
                  AppRouter.goToStatistics(context);
                },
              ),
              _buildQuickActionCard(
                icon: Icons.notifications,
                title: 'Уведомления',
                subtitle: 'Напоминания',
                onTap: () {
                  // TODO: Показать уведомления
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Статистика посещаемости
          Text(
            'Моя посещаемость',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Посещаемость',
                  value: '85%',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Пропуски',
                  value: '3',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Карточка быстрого действия
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Карточка статистики
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// QR сканер для студентов (ввод кода на Web)
  Widget _buildQRScanner() {
    return _StudentQRScanner();
  }

  /// Расписание студента
  Widget _buildStudentSchedule() {
    return _StudentSchedule();
  }

  /// Статистика студента
  Widget _buildStudentStatistics() {
    return _StudentStatistics();
  }
}

// ======== QR SCANNER ========
class _StudentQRScanner extends StatefulWidget {
  @override
  State<_StudentQRScanner> createState() => _StudentQRScannerState();
}

class _StudentQRScannerState extends State<_StudentQRScanner> {
  final _qrController = TextEditingController();
  bool _isSubmitting = false;
  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _submitQRCode() async {
    final code = _qrController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _resultMessage = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.markAttendanceByQR(code);
      
      final message = result['message'] ?? 'Отмечено!';
      final lessonTitle = result['lesson']?['title'] ?? '';
      final groupName = result['lesson']?['groupName'] ?? '';

      setState(() {
        _isSuccess = true;
        _resultMessage = result['alreadyMarked'] == true
            ? '⚠️ $message'
            : '✅ $message\n📖 $lessonTitle\n👥 $groupName';
        _qrController.clear();
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _resultMessage = '❌ ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Отметить посещаемость',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Введите QR-код, предоставленный преподавателем',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // QR code input
          TextField(
            controller: _qrController,
            decoration: InputDecoration(
              labelText: 'QR-код',
              hintText: 'Например: lesson_1234567890',
              border: const OutlineInputBorder(),
              filled: true,
              prefixIcon: const Icon(Icons.qr_code),
              suffixIcon: _qrController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _qrController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submitQRCode(),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting || _qrController.text.trim().isEmpty
                  ? null
                  : _submitQRCode,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSubmitting ? 'Отправка...' : 'Отметиться'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Result message
          if (_resultMessage != null)
            Card(
              color: _isSuccess
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green[800] : Colors.red[800],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ======== STUDENT SCHEDULE ========
class _StudentSchedule extends StatefulWidget {
  @override
  State<_StudentSchedule> createState() => _StudentScheduleState();
}

class _StudentScheduleState extends State<_StudentSchedule> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _error;
  String? _expandedGroupId;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final apiService = ApiService();
      final groups = await apiService.getStudentGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadGroups, child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Вы пока не добавлены ни в одну группу',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Попросите преподавателя добавить вас в группу',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final lessons = (group['lessons'] as List?) ?? [];
          final teacherName = group['teacher']?['name'] ?? 'Преподаватель';
          final isExpanded = _expandedGroupId == group['id'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                // Group header
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (group['name'] ?? 'G')[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    group['name'] ?? 'Группа',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Преподаватель: $teacherName • ${lessons.length} занятий'),
                  trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      _expandedGroupId = isExpanded ? null : group['id'];
                    });
                  },
                ),
                // Lessons list (expanded)
                if (isExpanded)
                  ...lessons.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Занятий пока нет', style: TextStyle(color: Colors.grey)),
                          )
                        ]
                      : lessons.map((lesson) {
                          final date = lesson['date'] != null
                              ? DateTime.tryParse(lesson['date'])
                              : null;
                          final hasAttendance = (lesson['attendance'] as List?)?.isNotEmpty ?? false;
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                            leading: Icon(
                              hasAttendance ? Icons.check_circle : Icons.circle_outlined,
                              color: hasAttendance ? Colors.green : Colors.grey,
                            ),
                            title: Text(lesson['title'] ?? 'Занятие'),
                            subtitle: Text(
                              date != null
                                  ? '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                                      '${lesson['startTime'] != null ? ' • ${lesson['startTime']}' : ''}'
                                      '${lesson['type'] != null ? ' • ${lesson['type']}' : ''}'
                                  : '-',
                            ),
                            trailing: hasAttendance
                                ? const Chip(
                                    label: Text('✓', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    backgroundColor: Colors.green,
                                    visualDensity: VisualDensity.compact,
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: () => _showLessonDetail(context, lesson, group['name'] ?? '', hasAttendance),
                          );
                        }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLessonDetail(BuildContext context, dynamic lesson, String groupName, bool hasAttendance) {
    final date = lesson['date'] != null ? DateTime.tryParse(lesson['date']) : null;
    final qrCodeController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            bool isSubmitting = false;
            String? resultMsg;
            bool resultSuccess = false;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16, right: 16, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson['title'] ?? 'Занятие',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Info
                    if (groupName.isNotEmpty) _detailRow(Icons.group, 'Группа', groupName),
                    if (lesson['type'] != null) _detailRow(Icons.class_, 'Тип', lesson['type']),
                    if (date != null)
                      _detailRow(Icons.calendar_today, 'Дата',
                          '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}'),
                    if (lesson['startTime'] != null)
                      _detailRow(Icons.access_time, 'Время',
                          '${lesson['startTime']} - ${lesson['endTime'] ?? ''}'),
                    if (lesson['classroom'] != null) _detailRow(Icons.location_on, 'Аудитория', lesson['classroom']),
                    if (lesson['description'] != null && lesson['description'].toString().isNotEmpty)
                      _detailRow(Icons.notes, 'Описание', lesson['description']),

                    const SizedBox(height: 20),
                    const Divider(),

                    // Attendance status
                    if (hasAttendance)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Вы уже отметились на этом занятии ✓',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      const Text(
                        'Отметить посещаемость',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Введите QR-код от преподавателя:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qrCodeController,
                        decoration: const InputDecoration(
                          labelText: 'QR-код',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final code = qrCodeController.text.trim();
                            if (code.isEmpty) return;
                            
                            setModalState(() { isSubmitting = true; });
                            
                            try {
                              final apiService = ApiService();
                              final result = await apiService.markAttendanceByQR(code);
                              
                              Navigator.pop(ctx);
                              _loadGroups(); // Refresh
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Отмечено!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() { isSubmitting = false; });
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check),
                          label: Text(isSubmitting ? 'Отправка...' : 'Отметиться'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ======== STUDENT STATISTICS ========
class _StudentStatistics extends StatefulWidget {
  @override
  State<_StudentStatistics> createState() => _StudentStatisticsState();
}

class _StudentStatisticsState extends State<_StudentStatistics> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final apiService = ApiService();
      final data = await apiService.getMyAttendance();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadStats, child: const Text('Повторить')),
          ],
        ),
      );
    }

    final stats = _data?['stats'] as Map<String, dynamic>? ?? {};
    final attendance = (_data?['attendance'] as List?) ?? [];
    final percentage = stats['percentage'] ?? 0;
    final totalLessons = stats['totalLessons'] ?? 0;
    final present = stats['present'] ?? 0;
    final late_ = stats['late'] ?? 0;
    final absent = stats['absent'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall percentage card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Общая посещаемость',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: percentage / 100.0,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[300],
                            color: percentage >= 75
                                ? Colors.green
                                : percentage >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: percentage >= 75
                                ? Colors.green
                                : percentage >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              _buildMiniStat('Всего', '$totalLessons', Icons.school, Colors.blue),
              const SizedBox(width: 8),
              _buildMiniStat('Был(а)', '$present', Icons.check_circle, Colors.green),
              const SizedBox(width: 8),
              _buildMiniStat('Опоздал', '$late_', Icons.watch_later, Colors.orange),
              const SizedBox(width: 8),
              _buildMiniStat('Пропуск', '$absent', Icons.cancel, Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Attendance history
          Text(
            'История посещений',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (attendance.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Записей о посещаемости пока нет',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            )
          else
            ...attendance.map((record) {
              final lesson = record['lesson'] as Map<String, dynamic>? ?? {};
              final group = lesson['group'] as Map<String, dynamic>? ?? {};
              final status = record['status'] ?? 'absent';
              final date = record['timestamp'] != null
                  ? DateTime.tryParse(record['timestamp'])
                  : null;

              Color statusColor;
              IconData statusIcon;
              String statusText;
              switch (status) {
                case 'present':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  statusText = 'Присутствовал';
                  break;
                case 'late':
                  statusColor = Colors.orange;
                  statusIcon = Icons.watch_later;
                  statusText = 'Опоздал';
                  break;
                default:
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  statusText = 'Отсутствовал';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(lesson['title'] ?? 'Занятие'),
                  subtitle: Text(
                    '${group['name'] ?? ''}'
                    '${date != null ? ' • ${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}' : ''}',
                  ),
                  trailing: Chip(
                    label: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
