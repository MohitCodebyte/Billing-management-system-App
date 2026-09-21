
class ApiConstants {

  // Endpoints
  static const String login = "/auth/login";
  static const String registerBusiness = "/auth/register-business";
  static const String verifyOtp = "/auth/verify-otp";
  static const String me = "/auth/me";

  static const String dashboard = "/dashboard";

  static const String calculateCart = "/billing/calculate";
  static const String invoices = "/invoices";

  static const String products = "/products";
  static const String categories = "/products/categories";

  static const String inventoryStock = "/inventory/stock";
  static const String inventoryAdjust = "/inventory/adjust";
  static const String inventoryHistory = "/inventory/history";

  static const String customers = "/customers";
  static const String suppliers = "/suppliers";

  static const String purchases = "/purchases";
  static const String expenses = "/expenses";
  static const String expenseCategories = "/expenses/categories";

  static const String salesReturns = "/returns/sales";
  static const String purchaseReturns = "/returns/purchases";

  static const String creditNotes = "/notes/credit";
  static const String debitNotes = "/notes/debit";

  static const String reportSales = "/reports/sales";
  static const String reportProfitLoss = "/reports/profit-loss";
  static const String reportGst = "/reports/gst";
  static const String reportInventory = "/reports/inventory";

  static const String employees = "/employees";
  static const String branches = "/branches";
  static const String switchBranch = "/branches/switch";

  static const String businessSettings = "/settings/business";
  static const String printerSettings = "/settings/printer";

  static const String notifications = "/notifications";

  // Mandatory Brand & Attribution
  static const String appTitle = "BharatLedger Pro";
  static const String appTagline = "Smart Billing. Better Business.";
  static const String copyright = "© NexvoraTech LLP — Developed by Mohit";
  static const String copyrightAttribution = copyright;
  static const String version = "v4.2.0-PROD";
}
