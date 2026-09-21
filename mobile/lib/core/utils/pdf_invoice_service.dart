import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/models.dart';
import '../storage/local_store.dart';

class PdfInvoiceService {
  static Future<void> printOrShareInvoice(InvoiceModel invoice) async {
    final doc = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<pw.Document> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final business = LocalStore().getDocument('business');
    final settings = LocalStore().getDocument('settings');

    final bizName = business['name'] ?? 'Bharat Steels & Industrial Supplies';
    final bizGstin = business['gstin'] ?? '27AAACB2234L1Z2';
    final bizAddress = business['address'] ?? 'MIDC Phase II, Pune';
    final bizPhone = business['phone'] ?? '+91 98230 12345';
    final terms = settings['terms_and_conditions'] ?? 'Goods once sold will not be taken back.';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      bizName,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(bizAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text("GSTIN: $bizGstin | Ph: $bizPhone", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text("Invoice #: ${invoice.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text("Date: ${invoice.invoiceDate}", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("Due: ${invoice.dueDate}", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300, height: 24),

            // Bill To
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BILLED TO:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    if (invoice.customerPhone.isNotEmpty)
                      pw.Text("Phone: ${invoice.customerPhone}", style: const pw.TextStyle(fontSize: 10)),
                    if (invoice.customerGstin.isNotEmpty)
                      pw.Text("GSTIN: ${invoice.customerGstin}", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: "UPI://pay?pa=bharatledger@icici&pn=$bizName&am=${invoice.grandTotal}&tn=${invoice.invoiceNumber}",
                  width: 55,
                  height: 55,
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6), // #
                1: const pw.FlexColumnWidth(3.0), // Item
                2: const pw.FlexColumnWidth(1.0), // HSN
                3: const pw.FlexColumnWidth(1.0), // Qty
                4: const pw.FlexColumnWidth(1.2), // Rate
                5: const pw.FlexColumnWidth(1.0), // GST%
                6: const pw.FlexColumnWidth(1.4), // Total
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell('#', isHeader: true, align: pw.TextAlign.center),
                    _cell('Description of Goods', isHeader: true),
                    _cell('HSN', isHeader: true, align: pw.TextAlign.center),
                    _cell('Qty', isHeader: true, align: pw.TextAlign.right),
                    _cell('Rate (₹)', isHeader: true, align: pw.TextAlign.right),
                    _cell('GST', isHeader: true, align: pw.TextAlign.center),
                    _cell('Total (₹)', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Data rows
                ...invoice.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', align: pw.TextAlign.center),
                      _cell(item.productName),
                      _cell(item.hsnSac, align: pw.TextAlign.center),
                      _cell('${item.quantity} ${item.unit}', align: pw.TextAlign.right),
                      _cell(item.unitPrice.toStringAsFixed(2), align: pw.TextAlign.right),
                      _cell('${item.gstRate.toInt()}%', align: pw.TextAlign.center),
                      _cell(item.totalAmount.toStringAsFixed(2), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // Totals Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  child: pw.Column(
                    children: [
                      _summaryRow("Subtotal:", "₹${invoice.subtotal.toStringAsFixed(2)}"),
                      if (invoice.discountAmount > 0)
                        _summaryRow("Discount:", "- ₹${invoice.discountAmount.toStringAsFixed(2)}", isDiscount: true),
                      _summaryRow("Taxable Value:", "₹${invoice.taxableValue.toStringAsFixed(2)}"),
                      if (invoice.cgstAmount > 0)
                        _summaryRow("CGST:", "₹${invoice.cgstAmount.toStringAsFixed(2)}"),
                      if (invoice.sgstAmount > 0)
                        _summaryRow("SGST:", "₹${invoice.sgstAmount.toStringAsFixed(2)}"),
                      if (invoice.igstAmount > 0)
                        _summaryRow("IGST:", "₹${invoice.igstAmount.toStringAsFixed(2)}"),
                      if (invoice.additionalCharges > 0)
                        _summaryRow("Additional Charges:", "₹${invoice.additionalCharges.toStringAsFixed(2)}"),
                      if (invoice.roundOff != 0)
                        _summaryRow("Round Off:", "₹${invoice.roundOff.toStringAsFixed(2)}"),
                      pw.Divider(thickness: 1, color: PdfColors.grey400),
                      _summaryRow(
                        "Grand Total:",
                        "₹${invoice.grandTotal.toStringAsFixed(2)}",
                        isBold: true,
                        fontSize: 13,
                        color: PdfColors.blue900,
                      ),
                      _summaryRow("Amount Paid:", "₹${invoice.paidAmount.toStringAsFixed(2)}"),
                      _summaryRow(
                        "Balance Due:",
                        "₹${invoice.balanceAmount.toStringAsFixed(2)}",
                        isBold: true,
                        color: invoice.balanceAmount > 0 ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),

            // Terms & Signatory
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Terms & Conditions:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.SizedBox(height: 2),
                      pw.Text(terms, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("For $bizName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.SizedBox(height: 24),
                    pw.Text("Authorized Signatory", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _cell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
    double fontSize = 9,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.red700 : (color ?? PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
