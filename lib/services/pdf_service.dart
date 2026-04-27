import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'ai_service.dart';
import 'auth_service.dart';
import '../models/lesion.dart';

class PdfService {
  static Future<void> generateAndShareReport({
    required AnalysisResult result,
    required AuthService auth,
    File? imageFile,
  }) async {
    final pdf = pw.Document();

    pw.ImageProvider? netImage;
    if (imageFile != null && await imageFile.exists()) {
      netImage = pw.MemoryImage(await imageFile.readAsBytes());
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildUserInfo(auth),
            pw.SizedBox(height: 20),
            if (netImage != null) ...[
              _buildImageSection(netImage),
              pw.SizedBox(height: 20),
            ],
            _buildAnalysisSummary(result),
            pw.SizedBox(height: 20),
            _buildDetailedResults(result),
            pw.SizedBox(height: 40),
            _buildDisclaimer(),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'DermaScan_Report_${DateFormat('yyyyMMdd_HHmm').format(result.analyzedAt)}.pdf',
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'DermaScann AI',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.Text(
              'Skin Analysis Report',
              style: const pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Text(
          DateFormat('MMMM dd, yyyy').format(DateTime.now()),
          style: const pw.TextStyle(color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildImageSection(pw.ImageProvider image) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Lesion Image', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 200,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildUserInfo(AuthService auth) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Patient Information', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _infoField('Name', auth.userName)),
              pw.Expanded(child: _infoField('Age', auth.age?.toString() ?? 'N/A')),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _infoField('Email', auth.userEmail)),
              pw.Expanded(child: _infoField('Skin Type', auth.skinType ?? 'N/A')),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAnalysisSummary(AnalysisResult result) {
    final riskColor = result.riskLevel.label == 'High' 
        ? PdfColors.red 
        : (result.riskLevel.label == 'Medium' ? PdfColors.orange : PdfColors.green);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Analysis Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: riskColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              child: pw.Text(
                'Risk Level: ${result.riskLevel.label.toUpperCase()}',
                style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Text(
              'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
              style: pw.TextStyle(color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDetailedResults(AnalysisResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Clinical Observations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(result.explanation, style: const pw.TextStyle(lineSpacing: 1.5)),
        pw.SizedBox(height: 16),
        pw.Text('Recommendations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(result.recommendation, style: const pw.TextStyle(lineSpacing: 1.5)),
      ],
    );
  }

  static pw.Widget _buildDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        'DISCLAIMER: This report is generated by DermaScann AI and is intended for informational and tracking purposes only. It does NOT constitute a medical diagnosis. Please consult a board-certified dermatologist for a professional evaluation of any skin concern.',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<void> generateFullHistoryReport({
    required List<Lesion> lesions,
    required AuthService auth,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildUserInfo(auth),
            pw.SizedBox(height: 20),
            pw.Text('Full Lesion History Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Divider(),
            ...lesions.map((l) => _buildLesionSummary(l)),
            pw.SizedBox(height: 40),
            _buildDisclaimer(),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'DermaScan_Full_History_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildLesionSummary(Lesion lesion) {
    final riskColor = lesion.latestRisk.label == 'High' 
        ? PdfColors.red 
        : (lesion.latestRisk.label == 'Medium' ? PdfColors.orange : PdfColors.green);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(lesion.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: riskColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Text(
                  lesion.latestRisk.label.toUpperCase(),
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Location: ${lesion.bodyLocation}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('Last Scan: ${DateFormat('MMM dd, yyyy').format(lesion.lastScan)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text('Total Scans: ${lesion.scanHistory.length}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          if (lesion.notes.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Notes: ${lesion.notes}', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _infoField(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
