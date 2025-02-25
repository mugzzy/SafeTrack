import 'dart:io';
import 'dart:typed_data'; // <-- Add this import for Uint8List

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PDFGenerator {
  static Future<void> generateAttendanceReport({
    required String eventName,
    required Map<String, String> studentAttendance,
    required BuildContext context,
    bool share = false,
    bool saveToPublicDir = false,
  }) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Load the image from assets
    final imageBytes = await _loadImageFromAssets('assets/logaw.png');
    final pw.ImageProvider logo =
        pw.MemoryImage(Uint8List.fromList(imageBytes));

    // Add content to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Attendance Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('Event: $eventName',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 16),
                  pw.Table.fromTextArray(
                    headers: ['Student ID', 'Attendance Status'],
                    data: studentAttendance.entries.map((entry) {
                      return [entry.key, entry.value];
                    }).toList(),
                  ),
                ],
              ),
              // Add the logo at the upper-right corner as a circle
              pw.Positioned(
                top: 3,
                right: 16,
                child: pw.ClipOval(
                  child: pw.Image(logo, width: 70, height: 70), // Reduced size
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      // Save the PDF to the app's internal directory
      final internalDir = await getApplicationDocumentsDirectory();
      final internalFilePath = '${internalDir.path}/attendance_report.pdf';
      final internalFile = File(internalFilePath);
      await internalFile.writeAsBytes(await pdf.save());

      if (share) {
        // Share the file
        await Share.shareXFiles([XFile(internalFilePath)],
            text: 'Attendance report for $eventName.');
      }

      if (saveToPublicDir) {
        // Save to the public Downloads directory
        final externalDir = Directory('/storage/emulated/0/Download');
        if (!await externalDir.exists()) {
          await externalDir.create(recursive: true);
        }
        final publicFilePath = '${externalDir.path}/attendance_report.pdf';
        final publicFile = File(publicFilePath);
        await publicFile.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved at $publicFilePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate or save PDF: $e')),
      );
    }
  }

  // Helper function to load the image from assets
  static Future<List<int>> _loadImageFromAssets(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List();
  }
}
