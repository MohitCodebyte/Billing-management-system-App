from datetime import datetime
from app.extensions import db

class Notification(db.Model):
    __tablename__ = "notifications"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    type = db.Column(db.String(50), default="SYSTEM")  # LOW_STOCK, PAYMENT_RECEIVED, OVERDUE, INVOICE_CREATED, PURCHASE_CREATED, SYSTEM
    title = db.Column(db.String(150), nullable=False)
    message = db.Column(db.Text, nullable=False)
    reference_type = db.Column(db.String(50), nullable=True)
    reference_id = db.Column(db.Integer, nullable=True)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "user_id": self.user_id,
            "type": self.type,
            "title": self.title,
            "message": self.message,
            "reference_type": self.reference_type or "",
            "reference_id": self.reference_id,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
