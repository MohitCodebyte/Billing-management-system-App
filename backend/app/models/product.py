from datetime import datetime
from app.extensions import db

class Category(db.Model):
    __tablename__ = "categories"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=True)

    products = db.relationship("Product", backref="category_rel", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "name": self.name,
            "description": self.description or ""
        }

class Product(db.Model):
    __tablename__ = "products"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey("categories.id"), nullable=True)
    name = db.Column(db.String(150), nullable=False, index=True)
    sku = db.Column(db.String(50), nullable=False, index=True)
    barcode = db.Column(db.String(50), nullable=True, index=True)
    hsn_sac = db.Column(db.String(20), default="8481")
    unit = db.Column(db.String(20), default="PCS")  # PCS, BOX, KG, MTR, LTR, SET
    purchase_price = db.Column(db.Float, default=0.0)
    selling_price = db.Column(db.Float, nullable=False)
    mrp = db.Column(db.Float, nullable=False)
    gst_rate = db.Column(db.Float, default=18.0)  # 0, 5, 12, 18, 28
    min_stock = db.Column(db.Float, default=10.0)
    max_stock = db.Column(db.Float, default=1000.0)
    brand = db.Column(db.String(100), default="Standard")
    description = db.Column(db.Text, nullable=True)
    image_url = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    branch_stocks = db.relationship("BranchStock", backref="product", lazy=True, cascade="all, delete-orphan")

    def get_stock(self, branch_id=None):
        if branch_id:
            from app.models.inventory import BranchStock
            stock = BranchStock.query.filter_by(product_id=self.id, branch_id=branch_id).first()
            return stock.quantity if stock else 0.0
        return sum(bs.quantity for bs in self.branch_stocks)

    def to_dict(self, branch_id=None):
        current_stock = self.get_stock(branch_id)
        return {
            "id": self.id,
            "business_id": self.business_id,
            "category_id": self.category_id,
            "category_name": self.category_rel.name if self.category_rel else "General",
            "name": self.name,
            "sku": self.sku,
            "barcode": self.barcode or "",
            "hsn_sac": self.hsn_sac or "",
            "unit": self.unit,
            "purchase_price": self.purchase_price,
            "selling_price": self.selling_price,
            "mrp": self.mrp,
            "gst_rate": self.gst_rate,
            "min_stock": self.min_stock,
            "max_stock": self.max_stock,
            "brand": self.brand or "",
            "description": self.description or "",
            "image_url": self.image_url or "",
            "current_stock": current_stock,
            "is_low_stock": current_stock <= self.min_stock,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
