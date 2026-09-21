from datetime import datetime
from app.extensions import db

class Purchase(db.Model):
    __tablename__ = "purchases"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    supplier_id = db.Column(db.Integer, db.ForeignKey("suppliers.id"), nullable=False)
    purchase_number = db.Column(db.String(50), nullable=False, unique=True, index=True)
    supplier_invoice_number = db.Column(db.String(50), nullable=True)
    purchase_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    due_date = db.Column(db.Date, nullable=False)
    subtotal = db.Column(db.Float, default=0.0)
    discount_amount = db.Column(db.Float, default=0.0)
    taxable_value = db.Column(db.Float, default=0.0)
    cgst_amount = db.Column(db.Float, default=0.0)
    sgst_amount = db.Column(db.Float, default=0.0)
    igst_amount = db.Column(db.Float, default=0.0)
    additional_charges = db.Column(db.Float, default=0.0)
    round_off = db.Column(db.Float, default=0.0)
    grand_total = db.Column(db.Float, nullable=False)
    paid_amount = db.Column(db.Float, default=0.0)
    balance_amount = db.Column(db.Float, default=0.0)
    status = db.Column(db.String(30), default="RECEIVED", nullable=False)  # ORDERED, RECEIVED, PAID, PARTIAL, CANCELLED
    notes = db.Column(db.Text, nullable=True)
    created_by_user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    supplier = db.relationship("Supplier", backref="purchases", lazy=True)
    items = db.relationship("PurchaseItem", backref="purchase", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "supplier_id": self.supplier_id,
            "supplier_name": self.supplier.name if self.supplier else "Unknown",
            "supplier_phone": self.supplier.phone if self.supplier else "",
            "supplier_gstin": self.supplier.gstin if self.supplier else "",
            "purchase_number": self.purchase_number,
            "supplier_invoice_number": self.supplier_invoice_number or "",
            "purchase_date": self.purchase_date.isoformat() if self.purchase_date else None,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "subtotal": round(self.subtotal, 2),
            "discount_amount": round(self.discount_amount, 2),
            "taxable_value": round(self.taxable_value, 2),
            "cgst_amount": round(self.cgst_amount, 2),
            "sgst_amount": round(self.sgst_amount, 2),
            "igst_amount": round(self.igst_amount, 2),
            "total_gst": round(self.cgst_amount + self.sgst_amount + self.igst_amount, 2),
            "additional_charges": round(self.additional_charges, 2),
            "round_off": round(self.round_off, 2),
            "grand_total": round(self.grand_total, 2),
            "paid_amount": round(self.paid_amount, 2),
            "balance_amount": round(self.balance_amount, 2),
            "status": self.status,
            "notes": self.notes or "",
            "items": [item.to_dict() for item in self.items],
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class PurchaseItem(db.Model):
    __tablename__ = "purchase_items"

    id = db.Column(db.Integer, primary_key=True)
    purchase_id = db.Column(db.Integer, db.ForeignKey("purchases.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    product_name = db.Column(db.String(150), nullable=False)
    hsn_sac = db.Column(db.String(20), default="8481")
    quantity = db.Column(db.Float, default=1.0, nullable=False)
    unit = db.Column(db.String(20), default="PCS")
    unit_price = db.Column(db.Float, nullable=False)
    gst_rate = db.Column(db.Float, default=18.0)
    cgst_amount = db.Column(db.Float, default=0.0)
    sgst_amount = db.Column(db.Float, default=0.0)
    igst_amount = db.Column(db.Float, default=0.0)
    total_amount = db.Column(db.Float, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "purchase_id": self.purchase_id,
            "product_id": self.product_id,
            "product_name": self.product_name,
            "hsn_sac": self.hsn_sac,
            "quantity": self.quantity,
            "unit": self.unit,
            "unit_price": round(self.unit_price, 2),
            "gst_rate": self.gst_rate,
            "cgst_amount": round(self.cgst_amount, 2),
            "sgst_amount": round(self.sgst_amount, 2),
            "igst_amount": round(self.igst_amount, 2),
            "total_amount": round(self.total_amount, 2)
        }
