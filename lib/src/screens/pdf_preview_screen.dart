import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/health_profile.dart';
import '../services/ai_coach_service.dart';
import '../services/pdf_service.dart';
import '../services/translation_service.dart';
import '../state/aura_scope.dart';

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
              ? Center(child: Text('Hata: \$_error'))
              : PdfPreview(
                  build: (format) => PdfService.buildPdf(
                    format,
                    widget.profile,
                    _aiSummary!,
                    widget.langCode,
                  ),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                ),
    );
  }
}
