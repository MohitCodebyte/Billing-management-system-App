import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/empty_and_error.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  String _printerType = 'bluetooth'; // bluetooth, network, usb
  String _printerName = 'TVS RP-3200 Thermal';
  String _ipAddress = '192.168.1.120';
  int _port = 9100;
  String _paperSize = '80mm'; // 58mm, 80mm, A4
  bool _autoPrint = true;
  final _headerCtrl = TextEditingController(text: 'BHARAT INDUSTRIAL SUPPLY CORP\nGSTIN: 27AABCU9603R1ZM');
  final _footerCtrl = TextEditingController(text: 'Thank you for your business!\nAuthorized Signatory');

  @override
  void initState() {
    super.initState();
    _fetchPrinterSettings();
  }

  Future<void> _fetchPrinterSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiClient().get(ApiConstants.printerSettings);
    if (!mounted) return;

    if (res.success && res.data is Map) {
      final data = res.data;
      _printerType = data['printer_type'] ?? 'bluetooth';
      _printerName = data['printer_name'] ?? 'TVS RP-3200 Thermal';
      _ipAddress = data['ip_address'] ?? '192.168.1.120';
      _port = data['port'] ?? 9100;
      _paperSize = data['paper_size'] ?? '80mm';
      _autoPrint = data['auto_print'] ?? true;
      _headerCtrl.text = data['header_text'] ?? 'BHARAT INDUSTRIAL SUPPLY CORP\nGSTIN: 27AABCU9603R1ZM';
      _footerCtrl.text = data['footer_text'] ?? 'Thank you for your business!\nAuthorized Signatory';
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load printer settings';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final payload = {
      'printer_type': _printerType,
      'printer_name': _printerName,
      'ip_address': _ipAddress,
      'port': _port,
      'paper_size': _paperSize,
      'auto_print': _autoPrint,
      'header_text': _headerCtrl.text.trim(),
      'footer_text': _footerCtrl.text.trim(),
    };

    final res = await ApiClient().put(ApiConstants.printerSettings, body: payload);
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer settings saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to save printer settings')),
      );
    }
  }

  Future<void> _testPrint() async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: _paperSize == '58mm'
              ? const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm)
              : (_paperSize == '80mm'
                  ? const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm)
                  : PdfPageFormat.a4),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(_headerCtrl.text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Divider(thickness: 1),
                pw.Text('TEST PRINT SUCCESSFUL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.SizedBox(height: 6),
                pw.Text('Connection: ${_printerType.toUpperCase()}'),
                pw.Text('Format: $_paperSize'),
                pw.Text('Date: ${DateTime.now().toString().substring(0, 19)}'),
                pw.Divider(thickness: 1),
                pw.Text(_footerCtrl.text, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print test executed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Printer & Invoice Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPrinterSettings,
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _fetchPrinterSettings)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Hardware Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.print, color: AppColors.primaryBlue, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _printerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_printerType.toUpperCase()} • ${_paperSize.toUpperCase()} Thermal Head',
                                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.success, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ready',
                                      style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.flash_on, size: 18),
                                  label: const Text('Feed & Test Print'),
                                  onPressed: _testPrint,
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondaryText,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Printer unlinked.')),
                                  );
                                },
                                child: const Text('Disconnect'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Connection Channel
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CONNECTION CHANNEL',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTypeChip('bluetooth', 'Bluetooth', Icons.bluetooth),
                              const SizedBox(width: 8),
                              _buildTypeChip('network', 'Wi-Fi / LAN', Icons.wifi),
                              const SizedBox(width: 8),
                              _buildTypeChip('usb', 'USB OTG', Icons.usb),
                            ],
                          ),
                          if (_printerType == 'network') ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _ipAddress,
                              decoration: const InputDecoration(labelText: 'Printer IP Address (e.g. 192.168.1.120)'),
                              onChanged: (v) => _ipAddress = v.trim(),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue: '$_port',
                              decoration: const InputDecoration(labelText: 'Port (default: 9100)'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _port = int.tryParse(v) ?? 9100,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Paper Size & Layout
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PAPER SIZE & FORMAT',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildPaperChip('58mm', '58mm (2" POS)'),
                              const SizedBox(width: 8),
                              _buildPaperChip('80mm', '80mm (3" Thermal)'),
                              const SizedBox(width: 8),
                              _buildPaperChip('A4', 'A4 (Laser Full)'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Auto-print receipt on payment confirmation', style: TextStyle(fontSize: 13)),
                            value: _autoPrint,
                            onChanged: (val) => setState(() => _autoPrint = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header & Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECEIPT HEADER & FOOTER TEXT',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _headerCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Header Text (Printed at top)',
                              hintText: 'Company Name & GSTIN',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _footerCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Footer Text (Printed at bottom)',
                              hintText: 'Thank you message, returns policy',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save CTA
                    AppButton(
                      label: 'Save Printer Settings',
                      icon: Icons.save,
                      isLoading: _isSaving,
                      onPressed: _saveSettings,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _buildTypeChip(String key, String label, IconData icon) {
    final isSel = _printerType == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _printerType = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primaryBlue.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.primaryBlue : AppColors.border, width: isSel ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? AppColors.primaryBlue : AppColors.secondaryText, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? AppColors.primaryBlue : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperChip(String key, String label) {
    final isSel = _paperSize == key;
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        onSelected: (val) => setState(() => _paperSize = key),
        selectedColor: AppColors.primaryBlue,
        labelStyle: TextStyle(
          color: isSel ? Colors.white : AppColors.secondaryText,
          fontSize: 11,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
