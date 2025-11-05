import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/router.dart';
import '../widgets/auth_consumer.dart';
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

  /// QR сканер для студентов
  Widget _buildQRScanner() {
    return const Center(
      child: Text('QR Сканер - в разработке'),
    );
  }

  /// Расписание студента
  Widget _buildStudentSchedule() {
    return const Center(
      child: Text('Расписание студента - в разработке'),
    );
  }

  /// Статистика студента
  Widget _buildStudentStatistics() {
    return const Center(
      child: Text('Статистика студента - в разработке'),
    );
  }
}
