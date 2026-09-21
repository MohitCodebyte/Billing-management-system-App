from datetime import datetime
from app.extensions import db

class StockMovementType:
    IN = "IN"
    OUT = "OUT"
    ADJUSTMENT = "ADJUSTMENT"
    TRANSFER = "TRANSFER"
    DAMAGE = "DAMAGE"
    RETURN = "RETURN"

class BranchStock(db.Model):
    __tablename__ = "branch_stocks"

    id = db.Column(db.Integer, primary_key=True)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    quantity = db.Column(db.Float, default=0.0)
    reserved_quantity = db.Column(db.Float, default=0.0)
    location_rack = db.Column(db.String(50), nullable=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (db.UniqueConstraint("branch_id", "product_id", name="uq_branch_product"),)

    def to_dict(self):
        return {
            "id": self.id,
            "branch_id": self.branch_id,
            "product_id": self.product_id,
            "product_name": self.product.name if self.product else "",
            "sku": self.product.sku if self.product else "",
            "quantity": self.quantity,
            "reserved_quantity": self.reserved_quantity,
            "available_quantity": max(0.0, self.quantity - self.reserved_quantity),
            "location_rack": self.location_rack or "",
            "is_low_stock": self.quantity <= (self.product.min_stock if self.product else 10.0),
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }

class StockMovement(db.Model):
    __tablename__ = "stock_movements"

    id = db.Column(db.Integer, primary_key=True)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    movement_type = db.Column(db.String(30), nullable=False)  # IN, OUT, ADJUSTMENT, TRANSFER, DAMAGE, RETURN
    quantity = db.Column(db.Float, nullable=False)  # Always positive magnitude
    previous_quantity = db.Column(db.Float, nullable=False)
    new_quantity = db.Column(db.Float, nullable=False)
    reference_type = db.Column(db.String(30), nullable=True)  # INVOICE, PURCHASE, RETURN, MANUAL, ADJUSTMENT
    reference_id = db.Column(db.Integer, nullable=True)
    notes = db.Column(db.String(255), nullable=True)
    created_by_user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    product_rel = db.relationship("Product", foreign_keys=[product_id])

    def to_dict(self):
        return {
            "id": self.id,
            "branch_id": self.branch_id,
            "product_id": self.product_id,
            "product_name": self.product_rel.name if self.product_rel else "",
            "movement_type": self.movement_type,
            "quantity": self.quantity,
            "previous_quantity": self.previous_quantity,
            "new_quantity": self.new_quantity,
            "reference_type": self.reference_type or "",
            "reference_id": self.reference_id,
            "notes": self.notes or "",
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
