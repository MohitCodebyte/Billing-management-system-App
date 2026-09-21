from datetime import datetime
from app.extensions import db

class Business(db.Model):
    __tablename__ = "businesses"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    trade_name = db.Column(db.String(150), nullable=True)
    gstin = db.Column(db.String(20), nullable=True, index=True)
    phone = db.Column(db.String(20), nullable=False)
    email = db.Column(db.String(120), nullable=True)
    address = db.Column(db.Text, nullable=True)
    city = db.Column(db.String(100), nullable=True)
    state = db.Column(db.String(100), default="Maharashtra")
    pincode = db.Column(db.String(10), nullable=True)
    pan = db.Column(db.String(20), nullable=True)
    logo_url = db.Column(db.String(255), nullable=True)
    currency = db.Column(db.String(10), default="INR")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    branches = db.relationship("Branch", backref="business", lazy=True, cascade="all, delete-orphan")
    settings = db.relationship("BusinessSettings", backref="business", uselist=False, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "trade_name": self.trade_name or self.name,
            "gstin": self.gstin,
            "phone": self.phone,
            "email": self.email,
            "address": self.address,
            "city": self.city,
            "state": self.state,
            "pincode": self.pincode,
            "pan": self.pan,
            "currency": self.currency,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class Branch(db.Model):
    __tablename__ = "branches"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    name = db.Column(db.String(120), nullable=False)
    code = db.Column(db.String(30), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    address = db.Column(db.Text, nullable=True)
    city = db.Column(db.String(100), nullable=True)
    state = db.Column(db.String(100), default="Maharashtra")
    gstin = db.Column(db.String(20), nullable=True)
    is_head_office = db.Column(db.Boolean, default=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "name": self.name,
            "code": self.code,
            "phone": self.phone,
            "email": self.email,
            "address": self.address,
            "city": self.city,
            "state": self.state,
            "gstin": self.gstin,
            "is_head_office": self.is_head_office,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class BusinessSettings(db.Model):
    __tablename__ = "business_settings"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False, unique=True)
    invoice_prefix = db.Column(db.String(20), default="INV-")
    next_invoice_number = db.Column(db.Integer, default=1001)
    purchase_prefix = db.Column(db.String(20), default="PO-")
    next_purchase_number = db.Column(db.Integer, default=101)
    default_tax_rate = db.Column(db.Float, default=18.0)
    tax_type = db.Column(db.String(20), default="GST")
    terms_and_conditions = db.Column(db.Text, default="1. Goods once sold will not be taken back without original bill.\n2. Interest @ 18% p.a. will be charged if bill is not paid on due date.\n3. Subject to local jurisdiction only.")
    signature_url = db.Column(db.String(255), nullable=True)
    enable_e_invoicing = db.Column(db.Boolean, default=False)
    enable_e_way_bill = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "invoice_prefix": self.invoice_prefix,
            "next_invoice_number": self.next_invoice_number,
            "purchase_prefix": self.purchase_prefix,
            "next_purchase_number": self.next_purchase_number,
            "default_tax_rate": self.default_tax_rate,
            "tax_type": self.tax_type,
            "terms_and_conditions": self.terms_and_conditions,
            "enable_e_invoicing": self.enable_e_invoicing,
            "enable_e_way_bill": self.enable_e_way_bill
        }

class PrinterSettings(db.Model):
    __tablename__ = "printer_settings"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=True)
    printer_type = db.Column(db.String(30), default="BLUETOOTH")  # BLUETOOTH, WIFI, USB, NETWORK
    printer_name = db.Column(db.String(100), default="Thermal POS-80")
    ip_address = db.Column(db.String(50), nullable=True)
    port = db.Column(db.Integer, default=9100)
    paper_size = db.Column(db.String(20), default="80MM")  # 58MM, 80MM, A4
    auto_print = db.Column(db.Boolean, default=True)
    header_text = db.Column(db.String(200), default="BharatLedger Industrial Invoicing")
    footer_text = db.Column(db.String(200), default="Thank you for your business! Visit again.")

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "printer_type": self.printer_type,
            "printer_name": self.printer_name,
            "ip_address": self.ip_address,
            "port": self.port,
            "paper_size": self.paper_size,
            "auto_print": self.auto_print,
            "header_text": self.header_text,
            "footer_text": self.footer_text
        }
