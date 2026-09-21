from datetime import datetime
from app.extensions import db

class ExpenseCategory(db.Model):
    __tablename__ = "expense_categories"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "name": self.name,
            "description": self.description or ""
        }

class Expense(db.Model):
    __tablename__ = "expenses"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey("expense_categories.id"), nullable=True)
    title = db.Column(db.String(150), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    vendor = db.Column(db.String(150), nullable=True)
    payment_method = db.Column(db.String(50), default="CASH")
    expense_date = db.Column(db.Date, default=datetime.utcnow().date, nullable=False)
    notes = db.Column(db.Text, nullable=True)
    receipt_url = db.Column(db.String(255), nullable=True)
    created_by_user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    category = db.relationship("ExpenseCategory", backref="expenses", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "category_id": self.category_id,
            "category_name": self.category.name if self.category else "General",
            "title": self.title,
            "amount": round(self.amount, 2),
            "vendor": self.vendor or "",
            "payment_method": self.payment_method,
            "expense_date": self.expense_date.isoformat() if self.expense_date else None,
            "notes": self.notes or "",
            "receipt_url": self.receipt_url or "",
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
