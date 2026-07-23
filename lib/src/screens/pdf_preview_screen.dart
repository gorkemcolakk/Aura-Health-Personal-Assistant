import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../models/health_profile.dart';
import '../services/ai_coach_service.dart';
import '../services/pdf_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final HealthProfile profile;
  final String? apiKey;

  const PdfPreviewScreen({super.key, required this.profile, this.apiKey});

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
        title: const Text('Doktor Raporu (PDF)'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Yapay zeka doktor özetini hazırlıyor, lütfen bekleyin...'),
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
