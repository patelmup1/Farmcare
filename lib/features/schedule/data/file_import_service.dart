import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart'; 
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';

class FileImportService {
  
  /// Parses an Excel file and returns a list of tasks.
  Future<List<Map<String, dynamic>>> parseExcel(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    if (excel.tables.isEmpty) return [];

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    
    if (sheet == null || sheet.rows.isEmpty) return [];

    // Headers: Date, [Product1], [Product2]...
    final headers = sheet.rows.first.map((e) => e?.value?.toString() ?? '').toList();
    
    final List<Map<String, dynamic>> tasks = [];

    // Start from row 1
    for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        
        final dateCell = row[0]?.value;
        if (dateCell == null) continue;
        
        DateTime? date;
        if (dateCell is DateCellValue) {
            date = dateCell.asDateTimeLocal();
        } else if (dateCell is TextCellValue) {
             try {
               // Try standard formats or DD/MM/YYYY
               final val = dateCell.value.toString().trim();
               if (val.contains('/')) {
                 final parts = val.split('/');
                 if (parts.length == 3) {
                   // dd/mm/yyyy
                   date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                 }
               }
               date ??= DateTime.parse(val);
             } catch (_) {
               continue;
             }
        }
        
        if (date == null) continue;
        
        final buffer = StringBuffer();
        for (int c = 1; c < row.length; c++) {
            final cell = row[c]?.value;
            String? valStr;
             if (cell is TextCellValue) valStr = cell.value.toString();
            else if (cell is IntCellValue) valStr = cell.value.toString();
            else if (cell is DoubleCellValue) valStr = cell.value.toString();
            else if (cell is DateCellValue) valStr = cell.asDateTimeLocal.toString();
            else valStr = cell?.toString();

            if (valStr != null && valStr.trim().isNotEmpty && valStr != '0' && valStr != 'null') {
               final header = (c < headers.length) ? headers[c] : '';
               buffer.write(header.isNotEmpty ? '$header: $valStr, ' : '$valStr, ');
            }
        }
        
        if (buffer.isNotEmpty) {
           tasks.add({
             'date': date,
             'description': buffer.toString().substring(0, buffer.length - 2),
             'isCompleted': false,
           });
        }
    }
    return tasks;
  }

  Future<List<Map<String, dynamic>>> parsePdf(String path) async {
    final List<Map<String, dynamic>> tasks = [];
    try {
      final File file = File(path);
      final List<int> bytes = await file.readAsBytes();
      
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      // layoutText: true often helps with columnar data, but simple extraction + flattening works for this vertical split issue.
      // We will try extracting text and then processing the "soup".
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      // 1. Flatten Text: Remove newlines to fix split words (e.g. "ત\nા\nર\nી\nખ" -> "તારીખ")
      // We replace with space to avoid merging separate words, but for split characters we might need empty string?
      // In the debug output, "ખ\nે\nત\nર" became "ખેતર" only if merged with empty string.
      // But "Date\nDescription" merging with empty string becomes "DateDescription".
      // Heuristic: If line is single char, merge with empty. If longer, merge with space. 
      // Simplified approach: Merge with Space, then regex to find dates, strip spaces inside dates?
      // No, the debug showed "1\n9\n/\n1\n1" -> "19/11". So we MUST merge with empty string to fix split dates/words.
      // But we risk merging "Word1\nWord2" -> "Word1Word2". 
      // Compromise: Remove '\n' but keep ' ' (spaces). 
      // The debug log showed: Line: "ખ", Line: "ે". No spaces. 
      // So removing \n is crucial.
      
      // 1. Flatten Text: Smart Merge
      // Split by newlines. 
      // If line ends with a Gujarati char and next starts with one, merge (no space).
      // Otherwise merge with space (to keep numbers/english words separate).
      final lines = text.split('\n');
      final buffer = StringBuffer();
      
      // Gujarati Unicode Range: \u0A80-\u0AFF
      final gujaratiRegex = RegExp(r'[\u0A80-\u0AFF]');
      
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;
        
        buffer.write(line);
        
        if (i < lines.length - 1) {
          String nextLine = lines[i+1].trim();
          if (nextLine.isNotEmpty) {
             // Check if we should merge tight or with space
             bool currentIsGuj = gujaratiRegex.hasMatch(line.characters.last);
             bool nextIsGuj = gujaratiRegex.hasMatch(nextLine.characters.first);
             
             if (currentIsGuj && nextIsGuj) {
               // Likely split word: "ખ" + "ે"
               // Don't add space
             } else {
               // Different types or numbers: "18" + "15" -> "18 15"
               buffer.write(' ');
             }
          }
        }
      }
      
      final flattened = buffer.toString();

      // 2. Regex for Dates: DD/MM/YYYY or YYYY-MM-DD
      // Added strict group capture to validate ranges.
      final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
      
      final matches = dateRegex.allMatches(flattened);
      
      int lastMatchEnd = 0;
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        final p1 = int.parse(match.group(1)!);
        final p2 = int.parse(match.group(2)!);
        final p3 = int.parse(match.group(3)!);

        // Determine Day/Month/Year
        // Assuming DD/MM/YYYY or MM/DD/YYYY? 
        // Given India/Gujarati context, likely DD/MM/YYYY.
        final day = p1;
        final month = p2;
        int year = p3;
        
        // Fix 2-digit year
        if (year < 100) year += 2000;

        // Validation (Filter out NPK ratios like 13-0-45)
        if (month < 1 || month > 12) continue;
        if (day < 1 || day > 31) continue;
        if (year < 2000 || year > 2100) continue; // Sanity check for crop years

        final date = DateTime(year, month, day);
        
        // 3. Extract Description
        // Text *before* this date (from last match) is the context.
        String desc = '';
        if (lastMatchEnd > 0) {
           // Get text between last date and current date
           String rawDesc = flattened.substring(lastMatchEnd, match.start);
           
           // Cleanup: Text often ends with numbers from the PREVIOUS task's dose. 
           // We might want to keep them or try to strip them.
           // For now, let's just trim.
           desc = rawDesc.trim();
        } else {
           // First match. Check if there's text before it.
           // e.g. "Sowing Date :- 19/11/2025" -> prev text is "Sowing Date :- "
           desc = flattened.substring(0, match.start).trim();
        }
        
        // Clean up common noise
        desc = desc.replaceAll(RegExp(r'[:\-]'), ' ').trim(); // Remove standalone : or -
        
        // If desc is just numbers, it's likely dose instructions for the PREVIOUS task, 
        // effectively leaving THIS task with no name. 
        // If it matches pure digits/spaces, maybe label it "Scheduled Task"?
        if (desc.isNotEmpty) {
           // Heuristic: If desc is very long, truncated it? No, keep it.
           tasks.add({
             'date': date,
             'description': desc.isNotEmpty ? desc : 'Task', // Fallback
             'isCompleted': false,
           });
        }
        
        lastMatchEnd = match.end;
      }
      
    } catch (e) {
      debugPrint('PDF Parse Error: $e');
    }
    return tasks;
  }
}
