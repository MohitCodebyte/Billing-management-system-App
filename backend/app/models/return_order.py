from datetime import datetime
from app.extensions import db

class SalesReturn(db.Model):
    __tablename__ = "sales_returns"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    invoice_id = db.Column(db.Integer, db.ForeignKey("invoices.id"), nullable=False)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.id"), nullable=False)
    return_number = db.Column(db.String(50), nullable=False, unique=True, index=True)
    return_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    refund_type = db.Column(db.String(30), default="CREDIT_NOTE")  # CREDIT_NOTE, CASH, UPI
    total_amount = db.Column(db.Float, nullable=False)
    tax_amount = db.Column(db.Float, default=0.0)
    reason = db.Column(db.String(255), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(30), default="COMPLETED")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    customer = db.relationship("Customer", foreign_keys=[customer_id])
    invoice = db.relationship("Invoice", foreign_keys=[invoice_id])
    items = db.relationship("ReturnItem", primaryjoin="and_(ReturnItem.return_id==SalesReturn.id, ReturnItem.return_type=='SALES')", foreign_keys="[ReturnItem.return_id]", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "invoice_id": self.invoice_id,
            "invoice_number": self.invoice.invoice_number if self.invoice else "",
            "customer_id": self.customer_id,
            "customer_name": self.customer.name if self.customer else "",
            "return_number": self.return_number,
            "return_date": self.return_date.isoformat() if self.return_date else None,
            "refund_type": self.refund_type,
            "total_amount": round(self.total_amount, 2),
            "tax_amount": round(self.tax_amount, 2),
            "reason": self.reason or "",
            "notes": self.notes or "",
            "status": self.status,
            "items": [item.to_dict() for item in self.items],
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class PurchaseReturn(db.Model):
    __tablename__ = "purchase_returns"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    purchase_id = db.Column(db.Integer, db.ForeignKey("purchases.id"), nullable=False)
    supplier_id = db.Column(db.Integer, db.ForeignKey("suppliers.id"), nullable=False)
    return_number = db.Column(db.String(50), nullable=False, unique=True, index=True)
    return_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    refund_type = db.Column(db.String(30), default="DEBIT_NOTE")  # DEBIT_NOTE, CASH, BANK
    total_amount = db.Column(db.Float, nullable=False)
    tax_amount = db.Column(db.Float, default=0.0)
    reason = db.Column(db.String(255), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(30), default="COMPLETED")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    supplier = db.relationship("Supplier", foreign_keys=[supplier_id])
    purchase = db.relationship("Purchase", foreign_keys=[purchase_id])
    items = db.relationship("ReturnItem", primaryjoin="and_(ReturnItem.return_id==PurchaseReturn.id, ReturnItem.return_type=='PURCHASE')", foreign_keys="[ReturnItem.return_id]", lazy=True, overlaps="items")

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "purchase_id": self.purchase_id,
            "purchase_number": self.purchase.purchase_number if self.purchase else "",
            "supplier_id": self.supplier_id,
            "supplier_name": self.supplier.name if self.supplier else "",
            "return_number": self.return_number,
            "return_date": self.return_date.isoformat() if self.return_date else None,
            "refund_type": self.refund_type,
            "total_amount": round(self.total_amount, 2),
            "tax_amount": round(self.tax_amount, 2),
            "reason": self.reason or "",
            "notes": self.notes or "",
            "status": self.status,
            "items": [item.to_dict() for item in self.items],
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class ReturnItem(db.Model):
    __tablename__ = "return_items"

    id = db.Column(db.Integer, primary_key=True)
    return_type = db.Column(db.String(20), nullable=False)  # SALES, PURCHASE
    return_id = db.Column(db.Integer, nullable=False, index=True)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    product_name = db.Column(db.String(150), nullable=False)
    quantity = db.Column(db.Float, nullable=False)
    unit_price = db.Column(db.Float, nullable=False)
    gst_rate = db.Column(db.Float, default=18.0)
    total_amount = db.Column(db.Float, nullable=False)
    restock_inventory = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            "id": self.id,
            "return_type": self.return_type,
            "return_id": self.return_id,
            "product_id": self.product_id,
            "product_name": self.product_name,
            "quantity": self.quantity,
            "unit_price": round(self.unit_price, 2),
            "gst_rate": self.gst_rate,
            "total_amount": round(self.total_amount, 2),
            "restock_inventory": self.restock_inventory
        }
