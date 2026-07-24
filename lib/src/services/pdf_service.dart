import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/health_profile.dart';
import 'health_calculator.dart';
import 'translation_service.dart';

class PdfService {
  static Future<Uint8List> buildPdf(
      PdfPageFormat format, HealthProfile profile, String aiSummary, String langCode) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final now = DateTime.now();
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(now);

    final bmi = HealthCalculator.bmi(profile);

    final weeklySleep = HealthCalculator.getWeeklySleepData(profile);
    final avgSleep =
        weeklySleep.map((e) => e.hours).reduce((a, b) => a + b) / 7;

    final weeklyWater = HealthCalculator.getWeeklyWaterData(profile);
    final avgWater =
        weeklyWater.map((e) => e.amountMl).reduce((a, b) => a + b) / 7;

    final clinicalText = [
      if (profile.conditions.isNotEmpty) '${TranslationService.get('pdf_condition', langCode)}: ${profile.conditions}',
      if (profile.allergies.isNotEmpty) '${TranslationService.get('pdf_allergy', langCode)}: ${profile.allergies}',
    ].join('\n');

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('AURA HEALTH',
                      style: pw.TextStyle(
                          fontSize: 32,
                          font: fontBold,
                          color: PdfColors.teal800)),
                  pw.Text(TranslationService.get('pdf_title', langCode),
                      style: pw.TextStyle(
                          fontSize: 22, font: fontBold, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.teal300),
              pw.SizedBox(height: 12),

              // ── Hasta Bilgileri ──────────────────────────────────────
              pw.Text(TranslationService.get('pdf_patient_info', langCode),
                  style: pw.TextStyle(
                      fontSize: 18,
                      font: fontBold,
                      color: PdfColors.teal800)),
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
                        pw.Text('${TranslationService.get('pdf_name', langCode)}: ${profile.name}',
                            style: pw.TextStyle(
                                fontSize: 16,
                                font: fontBold,
                                color: PdfColors.black)),
                        pw.SizedBox(height: 6),
                        pw.Text('${TranslationService.get('pdf_gender', langCode)}: ${TranslationService.get(profile.gender == 'Erkek' ? 'prof_gender_m' : profile.gender == 'Kadın' ? 'prof_gender_f' : 'prof_gender_u', langCode)}',
                            style: pw.TextStyle(
                                fontSize: 16,
                                font: fontBold,
                                color: PdfColors.black)),
                        pw.SizedBox(height: 6),
                        pw.Text('${TranslationService.get('pdf_age', langCode)}: ${profile.age}',
                            style: pw.TextStyle(
                                fontSize: 16,
                                font: fontBold,
                                color: PdfColors.black)),
                        pw.SizedBox(height: 6),
                        pw.Text('${TranslationService.get('pdf_date', langCode)}: $formattedDate',
                            style: pw.TextStyle(
                                fontSize: 16,
                                font: fontBold,
                                color: PdfColors.black)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${TranslationService.get('pdf_height', langCode)}: ${profile.heightCm} cm',
                            style: pw.TextStyle(
                                fontSize: 16,
                                font: fontBold,
                                color: PdfColors.black)),
                        pw.SizedBox(height: 6),
                        pw.Text('${TranslationService.get('pdf_weight', langCode)}: ${profile.weightKg} kg',
                            style: pw.TextStyle(
                                fontSize: 16,
                                font: fontBold,
                                color: PdfColors.black)),
                        pw.SizedBox(height: 6),
                        pw.Text(
                            '${TranslationService.get('pdf_blood_type', langCode)}: ${profile.bloodType.isEmpty ? TranslationService.get('pdf_not_specified', langCode) : profile.bloodType}',
                            style: pw.TextStyle(
                                fontSize: 16,
                                font: fontBold,
                                color: PdfColors.black)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ── Sağlık Verileri ──────────────────────────────────────
              pw.Text(TranslationService.get('pdf_health_data', langCode),
                  style: pw.TextStyle(
                      fontSize: 18,
                      font: fontBold,
                      color: PdfColors.teal800)),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricBox(TranslationService.get('pdf_bmi', langCode), bmi.toStringAsFixed(1), 'kg/m2', fontBold),
                  _buildMetricBox(TranslationService.get('pdf_avg_water', langCode), '${avgWater.round()}', 'ml/gün', fontBold),
                  _buildMetricBox(
                      TranslationService.get('pdf_avg_sleep', langCode), avgSleep.toStringAsFixed(1), 'saat/gün', fontBold),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── Klinik Durum ─────────────────────────────────────────
              pw.Text(TranslationService.get('pdf_clinical_status', langCode),
                  style: pw.TextStyle(
                      fontSize: 16, font: fontBold, color: PdfColors.black)),
              pw.SizedBox(height: 6),
              pw.Text(
                clinicalText.isEmpty
                    ? TranslationService.get('pdf_no_critical', langCode)
                    : clinicalText,
                style: pw.TextStyle(
                    fontSize: 16, font: fontBold, color: PdfColors.black),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // ── Yapay Zeka Özeti ─────────────────────────────────────
              pw.Text(TranslationService.get('pdf_ai_summary_title', langCode),
                  style: pw.TextStyle(
                      fontSize: 18,
                      font: fontBold,
                      color: PdfColors.indigo800)),
              pw.SizedBox(height: 8),
              pw.Flexible(
                fit: pw.FlexFit.loose,
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(12)),
                    border: pw.Border.all(color: PdfColors.indigo200, width: 1.5),
                  ),
                  child: pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    alignment: pw.Alignment.topLeft,
                    child: pw.Text(
                      aiSummary,
                      style: pw.TextStyle(
                        fontSize: 15,
                        lineSpacing: 4,
                        font: fontBold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  ),
                ),
              ),
              
              pw.Spacer(),

              // Warning Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.orange200),
                ),
                child: pw.Center(
                  child: pw.Text(
                    TranslationService.get('pdf_footer_warning', langCode),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: 12,
                        font: fontBold,
                        color: PdfColors.orange900),
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

  static pw.Widget _buildMetricBox(String title, String value, String unit, pw.Font fontBold) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal400, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        color: PdfColors.teal50,
      ),
      child: pw.Column(
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 16,
                  font: fontBold,
                  color: PdfColors.teal900)),
          pw.SizedBox(height: 12),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 36,
                  font: fontBold,
                  color: PdfColors.teal900)),
          pw.SizedBox(height: 4),
          pw.Text(unit,
              style: pw.TextStyle(
                  fontSize: 14,
                  font: fontBold,
                  color: PdfColors.teal800)),
        ],
      ),
    );
  }
}
