import 'dart:io';
import 'dart:typed_data'; // For Uint8List

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class EventPDFGenerator {
  static Future<void> generateEventWiseAttendanceReport({
    required String reportTitle,
    required DateTime eventDate,
    required List<Map<String, dynamic>> eventData,
    required BuildContext context,
    bool share = false,
    bool saveToPublicDir = false,
  }) async {
    final pdf = pw.Document();

    // Load logo image from assets
    final imageBytes = await _loadImageFromAssets('assets/logaw.png');
    final pw.ImageProvider logo =
        pw.MemoryImage(Uint8List.fromList(imageBytes));

    // Format the event date
    final formattedDate =
        "${eventDate.year}-${eventDate.month}-${eventDate.day}";

    // Add content to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    reportTitle,
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(top: 1, right: 16, bottom: 5),
                    child: pw.ClipOval(
                      child: pw.Image(logo, width: 80, height: 80),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Event date
              pw.Text('Event Date: $formattedDate',
                  style: pw.TextStyle(fontSize: 16)),

              pw.SizedBox(height: 16),

              // Table data
              pw.Table.fromTextArray(
                headers: ['Event', 'Participants', 'Present', 'Absent'],
                data: eventData.map((event) {
                  return [
                    event['eventName'],
                    event['participants'].toString(),
                    event['present'].toString(),
                    event['absent'].toString(),
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
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
      final internalFilePath =
          '${internalDir.path}/event_wise_attendance_report.pdf';
      final internalFile = File(internalFilePath);
      await internalFile.writeAsBytes(await pdf.save());

      if (share) {
        // Share the file
        await Share.shareXFiles([XFile(internalFilePath)],
            text: 'Event-wise Attendance Report.');
      }

      if (saveToPublicDir) {
        // Save to the public Downloads directory
        final externalDir = Directory('/storage/emulated/0/Download');
        if (!await externalDir.exists()) {
          await externalDir.create(recursive: true);
        }
        final publicFilePath =
            '${externalDir.path}/event_wise_attendance_report.pdf';
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
