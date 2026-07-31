import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/health_profile.dart';
import '../models/medication.dart';
import '../services/ai_coach_service.dart';
import '../services/pdf_service.dart';
import '../services/translation_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final HealthProfile profile;
  final List<Medication> medications;
  final String? apiKey;
  final String langCode;
  final int days;

  const PdfPreviewScreen({super.key, required this.profile, required this.medications, this.apiKey, required this.langCode, this.days = 7});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  String? _aiSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAiSummary();
  }

  Future<void> _fetchAiSummary() async {
    try {
      final aiService = AiCoachService();
      final summary = await aiService.generateDoctorSummary(
        profile: widget.profile,
        medications: widget.medications,
        apiKey: widget.apiKey,
        langCode: widget.langCode,
        days: widget.days,
      );
      debugPrint('[PdfPreview] AI Summary received: "${summary.substring(0, summary.length.clamp(0, 100))}"');
      if (mounted) {
        setState(() {
          _aiSummary = summary.isEmpty
              ? (widget.langCode == 'en'
                  ? 'AI summary returned empty. Please check your API key in Settings.'
                  : 'Yapay zeka boş yanıt döndürdü. Lütfen Ayarlar bölümünden API anahtarınızı kontrol edin.')
              : summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PdfPreview] Error fetching AI summary: $e');
      if (mounted) {
        setState(() {
          _aiSummary = widget.langCode == 'en'
              ? 'AI summary error: $e'
              : 'Yapay zeka hatası: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekranın en-boy oranına göre PDF sayfası oluştur
    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final availableHeight = screenSize.height - appBarHeight;
    final availableWidth = screenSize.width;

    // Ekrana tam oturacak özel sayfa boyutu (piksel → PDF birimi dönüşümü)
    // PdfPageFormat birim: 1 pt = 1/72 inç
    // Ekranı doldurmak için aspect ratio'yu telefon ekranı oranına eşitliyoruz
    final pageWidth = 595.0; // A4 genişliği pt cinsinden
    final pageHeight = pageWidth * (availableHeight / availableWidth);

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.get('pdf_title', widget.langCode)),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(TranslationService.get('pdf_preparing', widget.langCode)),
                ],
              ),
            )
          : _error != null
              ? Center(child: Text('Hata: $_error'))
              : PdfPreview(
                  build: (format) => PdfService.buildPdf(
                    PdfPageFormat(pageWidth, pageHeight, marginAll: 0),
                    widget.profile,
                    _aiSummary!,
                    widget.langCode,
                    widget.days,
                  ),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  padding: EdgeInsets.zero,
                  initialPageFormat: PdfPageFormat(pageWidth, pageHeight),
                  scrollViewDecoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                  ),
                ),
    );
  }
}
