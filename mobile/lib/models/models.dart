class UserModel {
  final int id;
  final int? businessId;
  final int? branchId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final List<String> permissions;

  UserModel({
    required this.id,
    this.businessId,
    this.branchId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      businessId: json['business_id'],
      branchId: json['branch_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'Staff',
      isActive: json['is_active'] ?? true,
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class BusinessModel {
  final int id;
  final String name;
  final String tradeName;
  final String gstin;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String currency;

  BusinessModel({
    required this.id,
    required this.name,
    required this.tradeName,
    required this.gstin,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    this.currency = 'INR',
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      tradeName: json['trade_name'] ?? json['name'] ?? '',
      gstin: json['gstin'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? 'Maharashtra',
      currency: json['currency'] ?? 'INR',
    );
  }
}

class BranchModel {
  final int id;
  final int businessId;
  final String name;
  final String code;
  final String phone;
  final String address;
  final bool isHeadOffice;

  BranchModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.code,
    required this.phone,
    required this.address,
    required this.isHeadOffice,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      isHeadOffice: json['is_head_office'] ?? false,
    );
  }
}

class ProductModel {
  final int id;
  final int? categoryId;
  final String categoryName;
  final String name;
  final String sku;
  final String barcode;
  final String hsnSac;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double gstRate;
  final double minStock;
  final double currentStock;
  final bool isLowStock;

  ProductModel({
    required this.id,
    this.categoryId,
    this.categoryName = 'General',
    required this.name,
    required this.sku,
    required this.barcode,
    required this.hsnSac,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.mrp,
    required this.gstRate,
    required this.minStock,
    required this.currentStock,
    required this.isLowStock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? 'General',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      barcode: json['barcode'] ?? '',
      hsnSac: json['hsn_sac'] ?? '8481',
      unit: json['unit'] ?? 'PCS',
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 18.0,
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 10.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      isLowStock: json['is_low_stock'] ?? false,
    );
  }

  bool get isOutOfStock => currentStock <= 0;
}

class CustomerModel {
  final int id;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final String gstin;
  final String address;
  final String city;
  final String state;
  final double creditLimit;
  final double currentBalance;

  CustomerModel({
    required this.id,
    required this.name,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.gstin,
    required this.address,
    required this.city,
    required this.state,
    required this.creditLimit,
    required this.currentBalance,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      companyName: json['company_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      gstin: json['gstin'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? 'Maharashtra',
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 100000.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SupplierModel {
  final int id;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final String gstin;
  final String address;
  final String city;
  final String state;
  final double currentPayable;

  SupplierModel({
    required this.id,
    required this.name,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.gstin,
    required this.address,
    required this.city,
    required this.state,
    required this.currentPayable,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      companyName: json['company_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      gstin: json['gstin'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? 'Maharashtra',
      currentPayable: (json['current_payable'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvoiceItemModel {
  final int? id;
  final int productId;
  final String productName;
  final String hsnSac;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discountAmount;
  final double taxableAmount;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;

  InvoiceItemModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.hsnSac,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.discountAmount = 0.0,
    required this.taxableAmount,
    this.gstRate = 18.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    required this.totalAmount,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'],
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      hsnSac: json['hsn_sac'] ?? '8481',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'PCS',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (json['taxable_amount'] as num?)?.toDouble() ?? 0.0,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 18.0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'gst_rate': gstRate,
    };
  }
}

class InvoiceModel {
  final int id;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String customerGstin;
  final String invoiceNumber;
  final String invoiceDate;
  final String dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalGst;
  final double additionalCharges;
  final double roundOff;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final List<InvoiceItemModel> items;

  InvoiceModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerGstin,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalGst,
    required this.additionalCharges,
    required this.roundOff,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    required this.items,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<InvoiceItemModel> itemsList = rawItems.map((i) => InvoiceItemModel.fromJson(i)).toList();

    return InvoiceModel(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? 'Walk-in Customer',
      customerPhone: json['customer_phone'] ?? '',
      customerGstin: json['customer_gstin'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      invoiceDate: json['invoice_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxable_value'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0.0,
      totalGst: (json['total_gst'] as num?)?.toDouble() ?? 0.0,
      additionalCharges: (json['additional_charges'] as num?)?.toDouble() ?? 0.0,
      roundOff: (json['round_off'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'ISSUED',
      items: itemsList,
    );
  }
}

class DashboardStats {
  final double todaySales;
  final int todayInvoices;
  final double totalReceivables;
  final double totalPayables;
  final double totalInventoryValuation;
  final int lowStockCount;
  final int totalCustomers;
  final int totalProducts;

  DashboardStats({
    this.todaySales = 0.0,
    this.todayInvoices = 0,
    this.totalReceivables = 0.0,
    this.totalPayables = 0.0,
    this.totalInventoryValuation = 0.0,
    this.lowStockCount = 0,
    this.totalCustomers = 0,
    this.totalProducts = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0.0,
      todayInvoices: json['today_invoices'] ?? 0,
      totalReceivables: (json['total_receivables'] as num?)?.toDouble() ?? 0.0,
      totalPayables: (json['total_payables'] as num?)?.toDouble() ?? 0.0,
      totalInventoryValuation: (json['total_inventory_valuation'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: json['low_stock_count'] ?? 0,
      totalCustomers: json['total_customers'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
    );
  }
}
