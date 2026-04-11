import 'package:ekutir_agent_app/utils/translation_service.dart';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/farmer.dart';
import '../models/procurement.dart';

abstract class ReceiptService {
  Future<Uint8List> buildReceiptPdf({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  });

  Future<bool> shareReceipt({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  });

  Future<bool> printReceipt({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  });
}

class PdfReceiptService implements ReceiptService {
  @override
  Future<Uint8List> buildReceiptPdf({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  }) async {
    final document = pw.Document();

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    final harvestDate = record.selectedHarvestDate;
    document.addPage(
      pw.Page(
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'eK Acre Growth Procurement Receipt',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Farmer-facing proof of harvest and procurement.'.tr),
                pw.SizedBox(height: 24),
                row('Receipt No', record.receiptNumber ?? 'Pending'),
                row('Farmer', farmer.name),
                row('Phone', farmer.phone),
                row('Location', farmer.location),
                row('Crop', farmer.crop),
                row('Harvest Date', harvestDate == null
                    ? '-'
                    : '${harvestDate.day}/${harvestDate.month}/${harvestDate.year}'),
                row(
                  'Harvest Qty',
                  '${(record.quantityHarvestedKg ?? 0).toStringAsFixed(0)} kg',
                ),
                row(
                  'Final Qty',
                  '${(record.finalWeighingQtyKg ?? 0).toStringAsFixed(0)} kg',
                ),
                row('Rate / kg', '₹${record.ratePerKg.toStringAsFixed(0)}'),
                row('Total', '₹${record.totalAmount.toStringAsFixed(0)}'),
                row('Transport', record.transportAssigned
                    ? '${record.carrierNumber} / ${record.driverName}'
                    : 'Pending'),
                if (record.receiptMessage.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Message',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(record.receiptMessage),
                ],
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  @override
  Future<bool> shareReceipt({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  }) async {
    try {
      final bytes = await buildReceiptPdf(farmer: farmer, record: record);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${farmer.name.replaceAll(' ', '_')}_receipt.pdf',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> printReceipt({
    required FarmerProfile farmer,
    required ProcurementRecord record,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => buildReceiptPdf(farmer: farmer, record: record),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
