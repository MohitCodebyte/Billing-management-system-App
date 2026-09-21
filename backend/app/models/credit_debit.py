from datetime import datetime
from app.extensions import db

class CreditNote(db.Model):
    __tablename__ = "credit_notes"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.id"), nullable=False)
    invoice_id = db.Column(db.Integer, db.ForeignKey("invoices.id"), nullable=True)
    note_number = db.Column(db.String(50), nullable=False, unique=True, index=True)
    note_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    amount = db.Column(db.Float, nullable=False)
    taxable_amount = db.Column(db.Float, default=0.0)
    tax_amount = db.Column(db.Float, default=0.0)
    reason = db.Column(db.String(255), nullable=False)
    status = db.Column(db.String(30), default="ACTIVE")  # ACTIVE, APPLIED, CANCELLED
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    customer = db.relationship("Customer", foreign_keys=[customer_id])
    invoice = db.relationship("Invoice", foreign_keys=[invoice_id])

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "customer_id": self.customer_id,
            "customer_name": self.customer.name if self.customer else "",
            "invoice_id": self.invoice_id,
            "invoice_number": self.invoice.invoice_number if self.invoice else "",
            "note_number": self.note_number,
            "note_date": self.note_date.isoformat() if self.note_date else None,
            "amount": round(self.amount, 2),
            "taxable_amount": round(self.taxable_amount, 2),
            "tax_amount": round(self.tax_amount, 2),
            "reason": self.reason,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class DebitNote(db.Model):
    __tablename__ = "debit_notes"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    supplier_id = db.Column(db.Integer, db.ForeignKey("suppliers.id"), nullable=False)
    purchase_id = db.Column(db.Integer, db.ForeignKey("purchases.id"), nullable=True)
    note_number = db.Column(db.String(50), nullable=False, unique=True, index=True)
    note_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    amount = db.Column(db.Float, nullable=False)
    taxable_amount = db.Column(db.Float, default=0.0)
    tax_amount = db.Column(db.Float, default=0.0)
    reason = db.Column(db.String(255), nullable=False)
    status = db.Column(db.String(30), default="ACTIVE")  # ACTIVE, APPLIED, CANCELLED
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    supplier = db.relationship("Supplier", foreign_keys=[supplier_id])
    purchase = db.relationship("Purchase", foreign_keys=[purchase_id])

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "supplier_id": self.supplier_id,
            "supplier_name": self.supplier.name if self.supplier else "",
            "purchase_id": self.purchase_id,
            "purchase_number": self.purchase.purchase_number if self.purchase else "",
            "note_number": self.note_number,
            "note_date": self.note_date.isoformat() if self.note_date else None,
            "amount": round(self.amount, 2),
            "taxable_amount": round(self.taxable_amount, 2),
            "tax_amount": round(self.tax_amount, 2),
            "reason": self.reason,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
