import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../security/password_hasher.dart';

/// Pure Dart, 100% database-free JSON persistent storage.
/// Does not use SQLite, MySQL, PostgreSQL, or any database engine.
/// Stores structured JSON files locally using atomic file operations.
class LocalStore {
  static final LocalStore _instance = LocalStore._internal();
  factory LocalStore() => _instance;
  LocalStore._internal();

  File? _storageFile;
  Map<String, dynamic> _data = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize local store. If [filePath] is provided, uses that specific file (ideal for tests).
  Future<void> init({String? filePath}) async {
    try {
      if (filePath != null) {
        _storageFile = File(filePath);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        _storageFile = File('${directory.path}/bharat_ledger_data.json');
      }

      if (await _storageFile!.exists()) {
        final content = await _storageFile!.readAsString();
        if (content.trim().isNotEmpty) {
          try {
            _data = jsonDecode(content) as Map<String, dynamic>;
          } catch (e) {
            debugPrint("Corrupted local store file, resetting to seeds: $e");
            _data = _createInitialSeedData();
            await save();
          }
        } else {
          _data = _createInitialSeedData();
          await save();
        }
      } else {
        _data = _createInitialSeedData();
        await save();
      }
      _initialized = true;
    } catch (e) {
      debugPrint("LocalStore init fallback to in-memory: $e");
      _data = _createInitialSeedData();
      _initialized = true;
    }
  }

  /// Atomically saves the in-memory data to the local JSON file.
  Future<void> save() async {
    if (_storageFile == null) return;
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(_data);
      // Write to temp file then rename for atomic write guarantee
      final tempFile = File('${_storageFile!.path}.tmp');
      await tempFile.writeAsString(jsonString, flush: true);
      if (await tempFile.exists()) {
        await tempFile.rename(_storageFile!.path);
      }
    } catch (e) {
      debugPrint("Error writing local storage file: $e");
      // Direct write fallback
      try {
        await _storageFile!.writeAsString(jsonEncode(_data), flush: true);
      } catch (err) {
        debugPrint("Direct write fallback failed: $err");
      }
    }
  }

  // --- Collection Accessors ---

  List<Map<String, dynamic>> getCollection(String name) {
    final list = _data[name];
    if (list is List) {
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    _data[name] = <Map<String, dynamic>>[];
    return [];
  }

  void setCollection(String name, List<Map<String, dynamic>> items) {
    _data[name] = items;
  }

  Map<String, dynamic> getDocument(String name) {
    final doc = _data[name];
    if (doc is Map) {
      return Map<String, dynamic>.from(doc);
    }
    _data[name] = <String, dynamic>{};
    return {};
  }

  void setDocument(String name, Map<String, dynamic> doc) {
    _data[name] = doc;
  }

  int generateId(String collectionName) {
    final items = getCollection(collectionName);
    if (items.isEmpty) return 1;
    int maxId = 0;
    for (final it in items) {
      final id = (it['id'] as num?)?.toInt() ?? 0;
      if (id > maxId) maxId = id;
    }
    return maxId + 1;
  }

  // --- Backup & Restore ---

  String exportJsonString() {
    return const JsonEncoder.withIndent('  ').convert(_data);
  }

  Future<bool> restoreFromJsonString(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('business') &&
          decoded.containsKey('users')) {
        _data = decoded;
        await save();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Restore failed: $e");
      return false;
    }
  }

  Future<void> resetToInitialSeeds() async {
    _data = _createInitialSeedData();
    await save();
  }

  // --- Initial Seed Data ---

  Map<String, dynamic> _createInitialSeedData() {
    final adminPasswordHash = PasswordHasher.hashPassword("admin123");
    final cashierPasswordHash = PasswordHasher.hashPassword("cashier123");

    return {
      "version": "4.2.0-offline",
      "created_at": DateTime.now().toIso8601String(),
      "business": {
        "id": 1,
        "name": "Bharat Steels & Industrial Supplies",
        "trade_name": "BharatLedger Pro Mandi Store",
        "gstin": "27AAACB2234L1Z2",
        "phone": "+91 98230 12345",
        "email": "contact@bharatsteels.com",
        "address": "Plot No. 44, MIDC Industrial Area, Phase II",
        "city": "Pune",
        "state": "Maharashtra",
        "pincode": "411019",
        "currency": "INR"
      },
      "branches": [
        {
          "id": 1,
          "business_id": 1,
          "name": "Central Warehouse & Shop Floor",
          "code": "PUN-01",
          "phone": "+91 98230 12345",
          "email": "warehouse@bharatsteels.com",
          "address": "Plot No. 44, MIDC Phase II, Pune",
          "city": "Pune",
          "state": "Maharashtra",
          "gstin": "27AAACB2234L1Z2",
          "is_head_office": true
        },
        {
          "id": 2,
          "business_id": 1,
          "name": "Mumbai Mandi Depot",
          "code": "MUM-01",
          "phone": "+91 98200 54321",
          "email": "mumbai@bharatsteels.com",
          "address": "Gala 12, Iron Market, Carnac Bunder",
          "city": "Mumbai",
          "state": "Maharashtra",
          "gstin": "27AAACB2234L1Z2",
          "is_head_office": false
        }
      ],
      "settings": {
        "business_id": 1,
        "invoice_prefix": "BL-INV-",
        "next_invoice_number": 1001,
        "purchase_prefix": "BL-PO-",
        "next_purchase_number": 501,
        "default_tax_rate": 18.0,
        "terms_and_conditions": "1. Goods once sold will not be taken back.\n2. Interest @ 18% p.a. on delayed payments.",
        "enable_e_invoicing": true,
        "enable_e_way_bill": false
      },
      "printer_settings": {
        "business_id": 1,
        "branch_id": 1,
        "printer_type": "bluetooth",
        "printer_name": "POS-80 Industrial Thermal",
        "ip_address": "192.168.1.120",
        "port": 9100,
        "paper_size": "80mm",
        "auto_print": true,
        "header_text": "BHARAT STEELS & INDUSTRIAL SUPPLIES\nGSTIN: 27AAACB2234L1Z2",
        "footer_text": "Thank you for your business!\nAuthorized Signatory"
      },
      "users": [
        {
          "id": 1,
          "business_id": 1,
          "branch_id": 1,
          "name": "Mohit Sharma",
          "email": "admin@bharatledger.com",
          "phone": "+91 98230 12345",
          "password_hash": adminPasswordHash,
          "role": "Admin",
          "is_active": true,
          "permissions": ["all"]
        },
        {
          "id": 2,
          "business_id": 1,
          "branch_id": 1,
          "name": "Rahul Verma (Cashier)",
          "email": "cashier@bharatledger.com",
          "phone": "+91 98230 67890",
          "password_hash": cashierPasswordHash,
          "role": "Cashier",
          "is_active": true,
          "permissions": [
            "billing.view",
            "billing.create",
            "invoices.view",
            "customers.view",
            "customers.create",
            "products.view",
            "payments.view",
            "payments.create"
          ]
        }
      ],
      "categories": [
        {
          "id": 1,
          "business_id": 1,
          "name": "Industrial Valves",
          "description": "Cast iron & stainless steel valves"
        },
        {
          "id": 2,
          "business_id": 1,
          "name": "MS & GI Pipes",
          "description": "Heavy duty structural pipes"
        },
        {
          "id": 3,
          "business_id": 1,
          "name": "High Tensile Fasteners",
          "description": "Grade 8.8 bolts, nuts and washers"
        },
        {
          "id": 4,
          "business_id": 1,
          "name": "Welding Equipment",
          "description": "Electrodes, flux and welding accessories"
        }
      ],
      "products": [
        {
          "id": 1,
          "business_id": 1,
          "category_id": 1,
          "category_name": "Industrial Valves",
          "name": "Gate Valve 2 Inch CI Class 150",
          "sku": "VAL-GV-020",
          "barcode": "890123456701",
          "unit": "PCS",
          "purchase_price": 1250.0,
          "selling_price": 1650.0,
          "mrp": 1850.0,
          "gst_rate": 18.0,
          "hsn_sac": "8481",
          "min_stock": 15.0,
          "current_stock": 65.0,
          "is_low_stock": false
        },
        {
          "id": 2,
          "business_id": 1,
          "category_id": 1,
          "category_name": "Industrial Valves",
          "name": "Ball Valve 1 Inch SS 304 Threaded",
          "sku": "VAL-BV-010",
          "barcode": "890123456702",
          "unit": "PCS",
          "purchase_price": 420.0,
          "selling_price": 580.0,
          "mrp": 650.0,
          "gst_rate": 18.0,
          "hsn_sac": "8481",
          "min_stock": 25.0,
          "current_stock": 115.0,
          "is_low_stock": false
        },
        {
          "id": 3,
          "business_id": 1,
          "category_id": 2,
          "category_name": "MS & GI Pipes",
          "name": "MS Seamless Pipe 2.5 Inch SCH 40 (6m)",
          "sku": "PIP-MS-025",
          "barcode": "890123456703",
          "unit": "MTR",
          "purchase_price": 820.0,
          "selling_price": 1100.0,
          "mrp": 1250.0,
          "gst_rate": 18.0,
          "hsn_sac": "7304",
          "min_stock": 50.0,
          "current_stock": 240.0,
          "is_low_stock": false
        },
        {
          "id": 4,
          "business_id": 1,
          "category_id": 3,
          "category_name": "High Tensile Fasteners",
          "name": "High Tensile Hex Bolt M16 x 65mm Gr 8.8",
          "sku": "FAS-HT-1665",
          "barcode": "890123456704",
          "unit": "BOX",
          "purchase_price": 350.0,
          "selling_price": 490.0,
          "mrp": 550.0,
          "gst_rate": 18.0,
          "hsn_sac": "7318",
          "min_stock": 20.0,
          "current_stock": 6.0,
          "is_low_stock": true
        },
        {
          "id": 5,
          "business_id": 1,
          "category_id": 4,
          "category_name": "Welding Equipment",
          "name": "Mild Steel Welding Electrode E6013 3.15mm",
          "sku": "WLD-EL-315",
          "barcode": "890123456705",
          "unit": "BOX",
          "purchase_price": 280.0,
          "selling_price": 390.0,
          "mrp": 450.0,
          "gst_rate": 18.0,
          "hsn_sac": "8311",
          "min_stock": 30.0,
          "current_stock": 150.0,
          "is_low_stock": false
        }
      ],
      "customers": [
        {
          "id": 1,
          "business_id": 1,
          "name": "Apex Engineering & Fabricators",
          "company_name": "Apex Engg Pvt Ltd",
          "phone": "+91 98901 23456",
          "email": "purchase@apexengineering.com",
          "gstin": "27AAACA9876Q1ZA",
          "address": "Plot 10, Bhosari MIDC, Pune",
          "city": "Pune",
          "state": "Maharashtra",
          "credit_limit": 250000.0,
          "opening_balance": 15000.0,
          "current_balance": 15000.0
        },
        {
          "id": 2,
          "business_id": 1,
          "name": "Maharashtra Sugar Mills Ltd",
          "company_name": "Maharashtra Sugar Mills Ltd",
          "phone": "+91 98220 98765",
          "email": "stores@maharsugarmills.com",
          "gstin": "27AAACM4455K1Z8",
          "address": "Sugar Factory Road, Baramati",
          "city": "Baramati",
          "state": "Maharashtra",
          "credit_limit": 500000.0,
          "opening_balance": 0.0,
          "current_balance": 0.0
        }
      ],
      "suppliers": [
        {
          "id": 1,
          "business_id": 1,
          "name": "Jindal Steel & Tubing Corporation",
          "company_name": "Jindal Steel & Tubes Ltd",
          "phone": "+91 98110 54321",
          "email": "sales@jindalsteeltubes.com",
          "gstin": "07AAACJ1234F1ZX",
          "address": "Barakhamba Road, Connaught Place",
          "city": "New Delhi",
          "state": "Delhi",
          "opening_balance": 45000.0,
          "current_payable": 45000.0
        },
        {
          "id": 2,
          "business_id": 1,
          "name": "Audco Valve Distributors",
          "company_name": "Audco Flow Control India",
          "phone": "+91 98400 11223",
          "email": "orders@audcoflow.com",
          "gstin": "33AAACA3322N1Z1",
          "address": "Mount Road, Guindy",
          "city": "Chennai",
          "state": "Tamil Nadu",
          "opening_balance": 0.0,
          "current_payable": 0.0
        }
      ],
      "invoices": [],
      "payments": [],
      "purchases": [],
      "expenses": [],
      "sales_returns": [],
      "purchase_returns": [],
      "credit_notes": [],
      "debit_notes": [],
      "stock_movements": [],
      "ledger_entries": [
        {
          "id": 1,
          "business_id": 1,
          "customer_id": 1,
          "entry_date": DateTime.now().toIso8601String().substring(0, 10),
          "voucher_type": "OPENING",
          "voucher_number": "OP-001",
          "debit_amount": 15000.0,
          "credit_amount": 0.0,
          "narration": "Opening Balance Ledger Carryforward",
          "voucher_id": 0
        },
        {
          "id": 2,
          "business_id": 1,
          "supplier_id": 1,
          "entry_date": DateTime.now().toIso8601String().substring(0, 10),
          "voucher_type": "OPENING",
          "voucher_number": "OP-SUP-001",
          "debit_amount": 0.0,
          "credit_amount": 45000.0,
          "narration": "Supplier Opening Outstanding Balance",
          "voucher_id": 0
        }
      ],
      "notifications": [
        {
          "id": 1,
          "business_id": 1,
          "branch_id": 1,
          "type": "SYSTEM",
          "title": "Welcome to BharatLedger Pro",
          "message": "Offline-capable, local-first industrial billing & POS initialized successfully.",
          "created_at": DateTime.now().toIso8601String(),
          "is_read": false
        }
      ]
    };
  }
}
