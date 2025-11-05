import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

/// Сервис для экспорта данных в Excel
class ExcelExportService {
  static final ExcelExportService _instance = ExcelExportService._internal();
  factory ExcelExportService() => _instance;
  ExcelExportService._internal();

  /// Экспорт статистики группы в Excel
  Future<String> exportGroupStats({
    required Map<String, dynamic> groupStats,
    required String fileName,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Статистика группы'];

      // Настройка ширины колонок
      sheet.setColumnWidth(0, 25); // ФИО
      sheet.setColumnWidth(1, 15); // Всего занятий
      sheet.setColumnWidth(2, 15); // Посещено
      sheet.setColumnWidth(3, 15); // Процент
      sheet.setColumnWidth(4, 20); // Статус

      // Заголовки
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('ФИО');
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Всего занятий');
      sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Посещено');
      sheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Процент посещаемости');
      sheet.cell(CellIndex.indexByString('D1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Статус');
      sheet.cell(CellIndex.indexByString('E1')).cellStyle = headerStyle;

      // Данные студентов
      final studentStats = groupStats['studentStats'] as List<dynamic>;
      for (int i = 0; i < studentStats.length; i++) {
        final student = studentStats[i] as Map<String, dynamic>;
        final row = i + 2;

        // ФИО
        sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(student['studentName'] ?? '');
        
        // Всего занятий
        sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(student['totalLessons'] ?? 0);
        
        // Посещено
        sheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(student['presentCount'] ?? 0);
        
        // Процент посещаемости
        final percentage = student['attendancePercentage'] ?? 0.0;
        sheet.cell(CellIndex.indexByString('D$row')).value = DoubleCellValue(percentage);
        
        // Статус с цветовой индикацией
        final statusCell = sheet.cell(CellIndex.indexByString('E$row'));
        String statusText;
        ExcelColor backgroundColor;
        
        if (percentage >= 90) {
          statusText = 'Отличная посещаемость';
          backgroundColor = ExcelColor.green;
        } else if (percentage >= 70) {
          statusText = 'Хорошая посещаемость';
          backgroundColor = ExcelColor.yellow;
        } else if (percentage >= 50) {
          statusText = 'Удовлетворительная посещаемость';
          backgroundColor = ExcelColor.orange;
        } else {
          statusText = 'Неудовлетворительная посещаемость';
          backgroundColor = ExcelColor.red;
        }
        
        statusCell.value = TextCellValue(statusText);
        statusCell.cellStyle = CellStyle(
          backgroundColorHex: backgroundColor,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Добавляем информацию о группе
      final infoRow = studentStats.length + 4;
      sheet.cell(CellIndex.indexByString('A$infoRow')).value = TextCellValue('Информация о группе:');
      sheet.cell(CellIndex.indexByString('A$infoRow')).cellStyle = CellStyle(bold: true);
      
      sheet.cell(CellIndex.indexByString('A${infoRow + 1}')).value = TextCellValue('Название: ${groupStats['groupName']}');
      sheet.cell(CellIndex.indexByString('A${infoRow + 2}')).value = TextCellValue('Курс: ${groupStats['course']}');
      sheet.cell(CellIndex.indexByString('A${infoRow + 3}')).value = TextCellValue('Год: ${groupStats['year']}');
      sheet.cell(CellIndex.indexByString('A${infoRow + 4}')).value = TextCellValue('Количество студентов: ${groupStats['studentCount']}');
      sheet.cell(CellIndex.indexByString('A${infoRow + 5}')).value = TextCellValue('Всего занятий: ${groupStats['totalLessons']}');
      sheet.cell(CellIndex.indexByString('A${infoRow + 6}')).value = TextCellValue('Средняя посещаемость: ${(groupStats['averageAttendance'] as double).toStringAsFixed(1)}%');

      return await _saveExcelFile(excel, fileName);
    } catch (e) {
      throw Exception('Ошибка экспорта статистики группы: $e');
    }
  }

  /// Экспорт статистики по предметам в Excel
  Future<String> exportSubjectStats({
    required List<Map<String, dynamic>> subjectStats,
    required String fileName,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Статистика по предметам'];

      // Настройка ширины колонок
      sheet.setColumnWidth(0, 30); // Предмет
      sheet.setColumnWidth(1, 15); // Всего занятий
      sheet.setColumnWidth(2, 15); // Записей посещаемости
      sheet.setColumnWidth(3, 15); // Присутствовало
      sheet.setColumnWidth(4, 15); // Средний процент
      sheet.setColumnWidth(5, 20); // Группы

      // Заголовки
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Предмет');
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Всего занятий');
      sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Записей посещаемости');
      sheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Присутствовало');
      sheet.cell(CellIndex.indexByString('D1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Средний процент');
      sheet.cell(CellIndex.indexByString('E1')).cellStyle = headerStyle;
      
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Группы');
      sheet.cell(CellIndex.indexByString('F1')).cellStyle = headerStyle;

      // Данные предметов
      for (int i = 0; i < subjectStats.length; i++) {
        final subject = subjectStats[i];
        final row = i + 2;

        sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(subject['subject'] ?? '');
        sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(subject['totalLessons'] ?? 0);
        sheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(subject['totalAttendanceRecords'] ?? 0);
        sheet.cell(CellIndex.indexByString('D$row')).value = IntCellValue(subject['presentCount'] ?? 0);
        sheet.cell(CellIndex.indexByString('E$row')).value = DoubleCellValue(subject['averageAttendance'] ?? 0.0);
        
        final groups = subject['groups'] as List<dynamic>? ?? [];
        sheet.cell(CellIndex.indexByString('F$row')).value = TextCellValue(groups.join(', '));
      }

      return await _saveExcelFile(excel, fileName);
    } catch (e) {
      throw Exception('Ошибка экспорта статистики по предметам: $e');
    }
  }

  /// Экспорт детальной статистики в Excel
  Future<String> exportDetailedStats({
    required Map<String, dynamic> detailedStats,
    required String fileName,
  }) async {
    try {
      final excel = Excel.createExcel();
      
      // Общая статистика
      final overallSheet = excel['Общая статистика'];
      _createOverallStatsSheet(overallSheet, detailedStats);
      
      // Статистика по группам
      final groupsSheet = excel['Статистика по группам'];
      _createGroupsStatsSheet(groupsSheet, detailedStats);
      
      // Статистика студентов
      final studentsSheet = excel['Статистика студентов'];
      _createStudentsStatsSheet(studentsSheet, detailedStats);

      return await _saveExcelFile(excel, fileName);
    } catch (e) {
      throw Exception('Ошибка экспорта детальной статистики: $e');
    }
  }

  /// Создание листа общей статистики
  void _createOverallStatsSheet(Sheet sheet, Map<String, dynamic> stats) {
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 20);

    final overall = stats['overall'] as Map<String, dynamic>;
    final period = stats['period'] as Map<String, dynamic>;

    int row = 1;
    
    // Заголовок
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Детальная статистика посещаемости');
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(bold: true, fontSize: 16);
    row += 2;

    // Период
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Период:');
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue('${period['startDate']} - ${period['endDate']}');
    row += 2;

    // Общая статистика
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Общая статистика:');
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(bold: true);
    row++;

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Всего занятий');
    sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(overall['totalLessons'] ?? 0);
    row++;

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Записей посещаемости');
    sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(overall['totalAttendanceRecords'] ?? 0);
    row++;

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Средняя посещаемость');
    sheet.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(overall['averageAttendance'] ?? 0.0);
    row++;

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Количество групп');
    sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(overall['totalGroups'] ?? 0);
    row++;

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Количество студентов');
    sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(overall['totalStudents'] ?? 0);
  }

  /// Создание листа статистики по группам
  void _createGroupsStatsSheet(Sheet sheet, Map<String, dynamic> stats) {
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    final groupStats = stats['groupStats'] as Map<String, dynamic>;

    // Заголовки
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Группа');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Студентов');
    sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Занятий');
    sheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Записей');
    sheet.cell(CellIndex.indexByString('D1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Средний %');
    sheet.cell(CellIndex.indexByString('E1')).cellStyle = headerStyle;

    int row = 2;
    for (final entry in groupStats.entries) {
      final groupData = entry.value as Map<String, dynamic>;
      
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(groupData['groupName'] ?? '');
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(groupData['studentCount'] ?? 0);
      sheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(groupData['totalLessons'] ?? 0);
      sheet.cell(CellIndex.indexByString('D$row')).value = IntCellValue(groupData['totalAttendanceRecords'] ?? 0);
      sheet.cell(CellIndex.indexByString('E$row')).value = DoubleCellValue(groupData['averageAttendance'] ?? 0.0);
      row++;
    }
  }

  /// Создание листа статистики студентов
  void _createStudentsStatsSheet(Sheet sheet, Map<String, dynamic> stats) {
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    final studentStats = stats['studentStats'] as List<dynamic>;

    // Заголовки
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue,
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Студент');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Всего занятий');
    sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Посещено');
    sheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Процент');
    sheet.cell(CellIndex.indexByString('D1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Статус');
    sheet.cell(CellIndex.indexByString('E1')).cellStyle = headerStyle;

    int row = 2;
    for (final student in studentStats) {
      final studentData = student as Map<String, dynamic>;
      final percentage = studentData['attendancePercentage'] as double? ?? 0.0;
      
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(studentData['studentName'] ?? '');
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(studentData['totalLessons'] ?? 0);
      sheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(studentData['presentCount'] ?? 0);
      sheet.cell(CellIndex.indexByString('D$row')).value = DoubleCellValue(percentage);
      
      // Статус с цветовой индикацией
      final statusCell = sheet.cell(CellIndex.indexByString('E$row'));
      String statusText;
      ExcelColor backgroundColor;
      
      if (percentage >= 90) {
        statusText = 'Отличная';
        backgroundColor = ExcelColor.green;
      } else if (percentage >= 70) {
        statusText = 'Хорошая';
        backgroundColor = ExcelColor.yellow;
      } else if (percentage >= 50) {
        statusText = 'Удовлетворительная';
        backgroundColor = ExcelColor.orange;
      } else {
        statusText = 'Неудовлетворительная';
        backgroundColor = ExcelColor.red;
      }
      
      statusCell.value = TextCellValue(statusText);
      statusCell.cellStyle = CellStyle(
        backgroundColorHex: backgroundColor,
        horizontalAlign: HorizontalAlign.Center,
      );
      
      row++;
    }
  }

  /// Сохранение Excel файла
  Future<String> _saveExcelFile(Excel excel, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.xlsx';
      
      final file = File(filePath);
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return filePath;
      } else {
        throw Exception('Ошибка создания Excel файла');
      }
    } catch (e) {
      throw Exception('Ошибка сохранения Excel файла: $e');
    }
  }

  /// Поделиться Excel файлом
  Future<void> shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Статистика посещаемости');
    } catch (e) {
      throw Exception('Ошибка отправки файла: $e');
    }
  }
}
