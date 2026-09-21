from datetime import datetime
from app.extensions import db

class PaymentMethod:
    CASH = "CASH"
    UPI = "UPI"
    CARD = "CARD"
    BANK_TRANSFER = "BANK_TRANSFER"
    CREDIT = "CREDIT"
    SPLIT = "SPLIT"

class PaymentStatus:
    SUCCESSFUL = "SUCCESSFUL"
    PENDING = "PENDING"
    FAILED = "FAILED"
    REFUNDED = "REFUNDED"

class Payment(db.Model):
    __tablename__ = "payments"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    reference_type = db.Column(db.String(30), nullable=False)  # INVOICE, PURCHASE, ADVANCE, CUSTOMER_BALANCE
    reference_id = db.Column(db.Integer, nullable=True)
    party_type = db.Column(db.String(30), nullable=False)  # CUSTOMER, SUPPLIER
    party_id = db.Column(db.Integer, nullable=False)
    amount = db.Column(db.Float, nullable=False)
    payment_method = db.Column(db.String(30), default=PaymentMethod.CASH, nullable=False)
    transaction_ref = db.Column(db.String(100), nullable=True)
    payment_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    notes = db.Column(db.String(255), nullable=True)
    status = db.Column(db.String(30), default=PaymentStatus.SUCCESSFUL, nullable=False)
    created_by_user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    splits = db.relationship("SplitPaymentDetail", backref="payment", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "reference_type": self.reference_type,
            "reference_id": self.reference_id,
            "party_type": self.party_type,
            "party_id": self.party_id,
            "amount": round(self.amount, 2),
            "payment_method": self.payment_method,
            "transaction_ref": self.transaction_ref or "",
            "payment_date": self.payment_date.isoformat() if self.payment_date else None,
            "notes": self.notes or "",
            "status": self.status,
            "splits": [s.to_dict() for s in self.splits],
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class SplitPaymentDetail(db.Model):
    __tablename__ = "split_payment_details"

    id = db.Column(db.Integer, primary_key=True)
    payment_id = db.Column(db.Integer, db.ForeignKey("payments.id"), nullable=False)
    method = db.Column(db.String(30), nullable=False)  # CASH, UPI, CARD, CREDIT
    amount = db.Column(db.Float, nullable=False)
    reference = db.Column(db.String(100), nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "payment_id": self.payment_id,
            "method": self.method,
            "amount": round(self.amount, 2),
            "reference": self.reference or ""
        }
