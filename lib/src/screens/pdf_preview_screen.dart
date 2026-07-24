import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/health_profile.dart';
import '../services/ai_coach_service.dart';
import '../services/pdf_service.dart';
import '../services/translation_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final HealthProfile profile;
  final String? apiKey;
  final String langCode;

  const PdfPreviewScreen({super.key, required this.profile, this.apiKey, required this.langCode});

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
        apiKey: widget.apiKey,
        langCode: widget.langCode,
      );
      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
