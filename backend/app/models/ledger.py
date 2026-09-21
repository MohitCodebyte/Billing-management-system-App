from datetime import datetime
from app.extensions import db

class CustomerLedgerEntry(db.Model):
    __tablename__ = "customer_ledger_entries"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.id"), nullable=False)
    entry_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    voucher_type = db.Column(db.String(30), nullable=False)  # INVOICE, PAYMENT, SALES_RETURN, CREDIT_NOTE, OPENING_BALANCE
    voucher_number = db.Column(db.String(50), nullable=False)
    voucher_id = db.Column(db.Integer, nullable=True)
    debit_amount = db.Column(db.Float, default=0.0)   # Increase receivable
    credit_amount = db.Column(db.Float, default=0.0)  # Decrease receivable
    running_balance = db.Column(db.Float, default=0.0)
    narration = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    customer = db.relationship("Customer", backref="ledger_entries", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "customer_id": self.customer_id,
            "entry_date": self.entry_date.isoformat() if self.entry_date else None,
            "voucher_type": self.voucher_type,
            "voucher_number": self.voucher_number,
            "voucher_id": self.voucher_id,
            "debit_amount": round(self.debit_amount, 2),
            "credit_amount": round(self.credit_amount, 2),
            "running_balance": round(self.running_balance, 2),
            "narration": self.narration or "",
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class SupplierLedgerEntry(db.Model):
    __tablename__ = "supplier_ledger_entries"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    supplier_id = db.Column(db.Integer, db.ForeignKey("suppliers.id"), nullable=False)
    entry_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    voucher_type = db.Column(db.String(30), nullable=False)  # PURCHASE, PAYMENT, PURCHASE_RETURN, DEBIT_NOTE, OPENING_BALANCE
    voucher_number = db.Column(db.String(50), nullable=False)
    voucher_id = db.Column(db.Integer, nullable=True)
    debit_amount = db.Column(db.Float, default=0.0)   # Decrease payable
    credit_amount = db.Column(db.Float, default=0.0)  # Increase payable
    running_balance = db.Column(db.Float, default=0.0)
    narration = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    supplier = db.relationship("Supplier", backref="ledger_entries", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "supplier_id": self.supplier_id,
            "entry_date": self.entry_date.isoformat() if self.entry_date else None,
            "voucher_type": self.voucher_type,
            "voucher_number": self.voucher_number,
            "voucher_id": self.voucher_id,
            "debit_amount": round(self.debit_amount, 2),
            "credit_amount": round(self.credit_amount, 2),
            "running_balance": round(self.running_balance, 2),
            "narration": self.narration or "",
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
