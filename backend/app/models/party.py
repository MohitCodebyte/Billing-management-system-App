from datetime import datetime
from app.extensions import db

class Customer(db.Model):
    __tablename__ = "customers"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    name = db.Column(db.String(150), nullable=False)
    company_name = db.Column(db.String(150), nullable=True)
    phone = db.Column(db.String(20), nullable=False, index=True)
    email = db.Column(db.String(120), nullable=True)
    gstin = db.Column(db.String(20), nullable=True)
    pan = db.Column(db.String(20), nullable=True)
    address = db.Column(db.Text, nullable=True)
    city = db.Column(db.String(100), nullable=True)
    state = db.Column(db.String(100), default="Maharashtra")
    pincode = db.Column(db.String(10), nullable=True)
    credit_limit = db.Column(db.Float, default=100000.0)
    opening_balance = db.Column(db.Float, default=0.0)
    current_balance = db.Column(db.Float, default=0.0)  # Positive means customer owes us (Debit)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "name": self.name,
            "company_name": self.company_name or "",
            "phone": self.phone,
            "email": self.email or "",
            "gstin": self.gstin or "",
            "pan": self.pan or "",
            "address": self.address or "",
            "city": self.city or "",
            "state": self.state or "",
            "pincode": self.pincode or "",
            "credit_limit": self.credit_limit,
            "opening_balance": self.opening_balance,
            "current_balance": self.current_balance,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class Supplier(db.Model):
    __tablename__ = "suppliers"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    name = db.Column(db.String(150), nullable=False)
    company_name = db.Column(db.String(150), nullable=True)
    phone = db.Column(db.String(20), nullable=False, index=True)
    email = db.Column(db.String(120), nullable=True)
    gstin = db.Column(db.String(20), nullable=True)
    pan = db.Column(db.String(20), nullable=True)
    address = db.Column(db.Text, nullable=True)
    city = db.Column(db.String(100), nullable=True)
    state = db.Column(db.String(100), default="Maharashtra")
    pincode = db.Column(db.String(10), nullable=True)
    opening_balance = db.Column(db.Float, default=0.0)
    current_payable = db.Column(db.Float, default=0.0)  # Positive means we owe supplier (Credit)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "name": self.name,
            "company_name": self.company_name or "",
            "phone": self.phone,
            "email": self.email or "",
            "gstin": self.gstin or "",
            "pan": self.pan or "",
            "address": self.address or "",
            "city": self.city or "",
            "state": self.state or "",
            "pincode": self.pincode or "",
            "opening_balance": self.opening_balance,
            "current_payable": self.current_payable,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
