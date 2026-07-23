import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/health_profile.dart';
import 'health_calculator.dart';
import 'ai_coach_service.dart';

class PdfService {
  static Future<Uint8List> buildPdf(
      PdfPageFormat format, HealthProfile profile, String aiSummary) async {
    final pdf = pw.Document();

    // Use built-in Helvetica to prevent 30-second download hangs on emulator
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final now = DateTime.now();
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(now);

    final bmi = HealthCalculator.bmi(profile);
    
    // Calculate averages
    final weeklySleep = HealthCalculator.getWeeklySleepData(profile);
    final avgSleep = weeklySleep.map((e) => e.hours).reduce((a, b) => a + b) / 7;
    
    final weeklyWater = HealthCalculator.getWeeklyWaterData(profile);
    final avgWater = weeklyWater.map((e) => e.amountMl).reduce((a, b) => a + b) / 7;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('AURA HEALTH', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                  pw.Text('Doktor Raporu', style: pw.TextStyle(fontSize: 22, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.teal200),
              pw.SizedBox(height: 12),
              
              // Patient Info
              pw.Text('HASTA BILGILERI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Isim: ${_normalizeTurkish(profile.name)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Yas: ${profile.age}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Tarih: $formattedDate', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Boy: ${profile.heightCm} cm', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Kilo: ${profile.weightKg} kg', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Kan Grubu: ${profile.bloodType.isEmpty ? "Belirtilmemis" : _normalizeTurkish(profile.bloodType)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Health Metrics
              pw.Text('SAGLIK VERILERI (Son 7 Gun)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
              pw.SizedBox(height: 8),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricBox('VKI', bmi.toStringAsFixed(1), 'kg/m2'),
                  _buildMetricBox('Ort. Su', '${avgWater.round()}', 'ml/gun'),
                  _buildMetricBox('Ort. Uyku', avgSleep.toStringAsFixed(1), 'saat/gun'),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Text('Klinik Durum / Alerjiler:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(profile.conditions.isEmpty ? 'Belirtilen kritik durum yok.' : profile.conditions, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // AI Summary
              pw.Text('YAPAY ZEKA (AURA) DOKTOR OZETI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  border: pw.Border.all(color: PdfColors.indigo200),
                ),
                child: pw.Text(
                  _normalizeTurkish(aiSummary),
                  style: pw.TextStyle(
                    fontSize: 17,
                    lineSpacing: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
                child: pw.Text(
                  'Bu rapor Aura Health AI tarafindan otomatik olusturulmustur.\nTibbi kesinlik tasimaz, hekim degerlendirmesine sunulmak uzere hazirlanmistir.',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildMetricBox(String title, String value, String unit) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal300, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        color: PdfColors.teal50,
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
          pw.SizedBox(height: 12),
          pw.Text(value, style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
          pw.SizedBox(height: 4),
          pw.Text(unit, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
        ],
      ),
    );
  }

  static String _normalizeTurkish(String text) {
    return text
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U');
  }
}
