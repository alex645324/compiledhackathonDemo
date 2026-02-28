import 'dart:typed_data';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class FileParser {
  ({List<String> headers, List<List<dynamic>> rows}) parse(
      Uint8List bytes, String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'csv') return _parseCsv(bytes);
    if (ext == 'xlsx') return _parseXlsx(bytes);
    throw FormatException('Unsupported file type: .$ext');
  }

  ({List<String> headers, List<List<dynamic>> rows}) _parseCsv(
      Uint8List bytes) {
    final content = utf8.decode(bytes);
    final table = const CsvToListConverter().convert(content);
    if (table.isEmpty) throw FormatException('CSV file is empty.');
    final headers = table.first.map((e) => e.toString()).toList();
    final rows = table.skip(1).toList();
    return (headers: headers, rows: rows);
  }

  ({List<String> headers, List<List<dynamic>> rows}) _parseXlsx(
      Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    if (sheet.rows.isEmpty) throw FormatException('XLSX file is empty.');
    final headers = sheet.rows.first
        .map((cell) => _cellValue(cell?.value).toString())
        .toList();
    final rows = sheet.rows.skip(1).map((row) {
      return row.map((cell) => _cellValue(cell?.value)).toList();
    }).toList();
    return (headers: headers, rows: rows);
  }

  dynamic _cellValue(CellValue? v) {
    if (v == null) return '';
    return switch (v) {
      IntCellValue(:final value) => value.toDouble(),
      DoubleCellValue(:final value) => value,
      TextCellValue(:final value) => value,
      _ => v.toString(),
    };
  }
}
