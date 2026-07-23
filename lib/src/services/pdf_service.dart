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

    // İnternet sorunu çözüldüğü için artık Türkçe destekli Roboto fontunu anında indirebiliriz
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final now = DateTime.now();
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(now);

    final bmi = HealthCalculator.bmi(profile);
    
    // Calculate averages
    final weeklySleep = HealthCalculator.getWeeklySleepData(profile);
    final avgSleep = weeklySleep.map((e) => e.hours).reduce((a, b) => a + b) / 7;
    
    final weeklyWater = HealthCalculator.getWeeklyWaterData(profile);
    final avgWater = weeklyWater.map((e) => e.amountMl).reduce((a, b) => a + b) / 7;

    // Ignore the format passed by PdfPreview and use a compact custom size
    const pageFormat = PdfPageFormat(595, 580, marginAll: 20);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.max,
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
              pw.Text('HASTA BİLGİLERİ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
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
                        pw.Text('İsim: ${profile.name}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Yaş: ${profile.age}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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
                        pw.Text('Kan Grubu: ${profile.bloodType.isEmpty ? "Belirtilmemiş" : profile.bloodType}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Health Metrics
              pw.Text('SAĞLIK VERİLERİ (Son 7 Gün)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
              pw.SizedBox(height: 8),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricBox('VKİ', bmi.toStringAsFixed(1), 'kg/m2'),
                  _buildMetricBox('Ort. Su', '${avgWater.round()}', 'ml/gün'),
                  _buildMetricBox('Ort. Uyku', avgSleep.toStringAsFixed(1), 'saat/gün'),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Text('Klinik Durum / Alerjiler:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(
                [
                  if (profile.conditions.isNotEmpty) 'Durum/Tanı: ${profile.conditions}',
                  if (profile.allergies.isNotEmpty) 'Alerji: ${profile.allergies}',
                ].isEmpty
                    ? 'Belirtilen kritik durum veya alerji yok.'
                    : [
                        if (profile.conditions.isNotEmpty) 'Durum/Tanı: ${profile.conditions}',
                        if (profile.allergies.isNotEmpty) 'Alerji: ${profile.allergies}',
                      ].join('\n'),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // AI Summary
              pw.Text('YAPAY ZEKA (AURA) DOKTOR ÖZETİ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  border: pw.Border.all(color: PdfColors.indigo100),
                ),
                child: pw.Text(
                  aiSummary,
                  style: pw.TextStyle(
                    fontSize: 14,
                    lineSpacing: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              
              pw.Spacer(),
              
              pw.SizedBox(height: 12),
              
              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.orange200),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'DİKKAT: Bu rapor Aura Health Yapay Zeka (AI) Asistanı tarafından hasta verileri baz alınarak otomatik oluşturulmuştur.\nHiçbir tıbbi kesinlik taşımaz ve reçete yerine geçmez. Sadece uzman hekim değerlendirmesine ön bilgi sunmak amacıyla hazırlanmıştır.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.orange900, fontWeight: pw.FontWeight.bold),
                  ),
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
}
