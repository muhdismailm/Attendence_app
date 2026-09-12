import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import 'package:intl/intl.dart';

class ExcelReportService {
  /// Generates the Excel file based on the handwritten monthly matrix layout:
  /// Title: Month Name (e.g., "Attendance Report - September 2026")
  /// Columns: Roll No | Student Name | Timing | 1 | 2 | 3 | ... | 30/31 | Present | Absent | %
  /// Rows: 2 rows per student (Morning & Evening)
  static Future<File> generateMonthlyAttendanceExcel({
    required List<Student> students,
    required Map<String, AttendanceRecord> attendanceMap, // keyed by "${studentId}_${date}_$timing" or record.id
    required int year,
    required int month,
    String teamName = 'All Teams',
  }) async {
    final excel = Excel.createExcel();
    final monthDate = DateTime(year, month, 1);
    final monthName = DateFormat('MMMM yyyy').format(monthDate);
    final sheetName = '${teamName.replaceAll(' ', '_')}_${DateFormat('MMM_yyyy').format(monthDate)}';

    // Rename default sheet
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    // Number of days in the month
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Header styling
    final headerCellStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'), // Deep blue
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    final titleCellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
    );

    final subTitleCellStyle = CellStyle(
      fontSize: 10,
      italic: true,
      fontColorHex: ExcelColor.fromHexString('#64748B'),
    );

    // Row 0: Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('ATTENDANCE REPORT - $monthName (${teamName.toUpperCase()})')
      ..cellStyle = titleCellStyle;

    // Row 1: Generated Date
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = TextCellValue('Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}')
      ..cellStyle = subTitleCellStyle;

    // Row 3: Headers
    int headerRow = 3;
    final headers = <String>[
      'Roll No',
      'Student Name',
      'Timing',
      for (int d = 1; d <= daysInMonth; d++) d.toString(),
      'Total P',
      'Total A',
      'Attendance %',
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerCellStyle;
    }

    // Populate Student Rows (2 rows per student: Morning, Evening)
    int currentRow = headerRow + 1;

    final presentStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#15803D'), // Green
    );

    final absentStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#B91C1C'), // Red
    );

    final emptyStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#94A3B8'),
    );

    final regularStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
    );

    final centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
    );

    for (final student in students) {
      for (final session in ['Morning', 'Evening']) {
        final sessionLower = session.toLowerCase();
        int presentCount = 0;
        int absentCount = 0;

        // Col 0: Roll No
        final rollCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        rollCell.value = TextCellValue(student.rollNumber.padLeft(2, '0'));
        rollCell.cellStyle = centerStyle;

        // Col 1: Student Name
        final nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
        nameCell.value = TextCellValue(student.name);
        nameCell.cellStyle = regularStyle;

        // Col 2: Timing
        final timingCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
        timingCell.value = TextCellValue(session);
        timingCell.cellStyle = centerStyle;

        // Day columns (Col 3 to 3 + daysInMonth - 1)
        for (int d = 1; d <= daysInMonth; d++) {
          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(year, month, d));
          final keyComposite = AttendanceRecord.generateId(student.id, dateStr, sessionLower);
          final keyLegacy = AttendanceRecord.generateId(student.id, dateStr);

          AttendanceRecord? record = attendanceMap[keyComposite];
          if (record == null && attendanceMap.containsKey(keyLegacy)) {
            final leg = attendanceMap[keyLegacy]!;
            if (leg.timing == sessionLower) {
              record = leg;
            }
          }

          final dayCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + d, rowIndex: currentRow));
          if (record != null) {
            if (record.isPresent) {
              dayCell.value = TextCellValue('P');
              dayCell.cellStyle = presentStyle;
              presentCount++;
            } else {
              dayCell.value = TextCellValue('A');
              dayCell.cellStyle = absentStyle;
              absentCount++;
            }
          } else {
            dayCell.value = TextCellValue('-');
            dayCell.cellStyle = emptyStyle;
          }
        }

        // Summary columns
        final totalClasses = presentCount + absentCount;
        final pct = totalClasses > 0 ? (presentCount / totalClasses * 100).toStringAsFixed(1) : '0.0';

        // Total P
        final pCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + daysInMonth, rowIndex: currentRow));
        pCell.value = IntCellValue(presentCount);
        pCell.cellStyle = centerStyle;

        // Total A
        final aCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + daysInMonth, rowIndex: currentRow));
        aCell.value = IntCellValue(absentCount);
        aCell.cellStyle = centerStyle;

        // Percentage
        final pctCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5 + daysInMonth, rowIndex: currentRow));
        pctCell.value = TextCellValue('$pct%');
        pctCell.cellStyle = centerStyle;

        currentRow++;
      }
    }

    // Auto fit column widths roughly
    sheet.setColumnWidth(0, 10);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 14);
    for (int d = 1; d <= daysInMonth; d++) {
      sheet.setColumnWidth(2 + d, 6);
    }
    sheet.setColumnWidth(3 + daysInMonth, 10);
    sheet.setColumnWidth(4 + daysInMonth, 10);
    sheet.setColumnWidth(5 + daysInMonth, 15);

    // Save to device directory
    final bytes = excel.save();
    final tempDir = await getApplicationDocumentsDirectory();
    final sanitizedTeam = teamName.replaceAll(' ', '_');
    final fileName = 'Attendance_${sanitizedTeam}_${year}_${month.toString().padLeft(2, '0')}.xlsx';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes!, flush: true);

    return file;
  }

  /// Open file with device's default excel/spreadsheet viewer
  static Future<bool> openExcelFile(File file) async {
    try {
      final result = await OpenFilex.open(file.path);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  /// Share excel file via WhatsApp, Gmail, etc.
  static Future<void> shareExcelFile(File file, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: subject ?? 'Attendance Report',
        text: 'Monthly attendance report spreadsheet.',
      );
    } catch (_) {
      // Fallback without mimeType
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? 'Attendance Report',
      );
    }
  }


}
