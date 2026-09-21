import json
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from app.extensions import db

class Role:
    OWNER = "Owner"
    ADMIN = "Admin"
    MANAGER = "Manager"
    CASHIER = "Cashier"
    SALESPERSON = "Salesperson"
    ACCOUNTANT = "Accountant"
    INVENTORY_MANAGER = "Inventory Manager"
    STAFF = "Staff"

    ALL_ROLES = [OWNER, ADMIN, MANAGER, CASHIER, SALESPERSON, ACCOUNTANT, INVENTORY_MANAGER, STAFF]

    ROLE_PERMISSIONS = {
        OWNER: ["all"],
        ADMIN: ["all"],
        MANAGER: [
            "dashboard.view",
            "billing", "billing.view", "billing.create", "billing.edit",
            "invoices", "invoices.view", "invoices.create", "invoices.edit",
            "customers", "customers.view", "customers.create", "customers.edit",
            "products", "products.view", "products.create", "products.edit",
            "inventory", "inventory.view", "inventory.adjust",
            "stock.view", "stock.manage", "stock.history",
            "purchases", "purchases.view", "purchases.create", "purchases.edit",
            "suppliers", "suppliers.view", "suppliers.create", "suppliers.edit",
            "payments", "payments.view", "payments.create", "payments.edit",
            "expenses", "expenses.view", "expenses.create", "expenses.edit",
            "returns.sales", "returns.purchases",
            "ledger.customer",
            "reports.view", "reports.sales",
            "notifications.view",
        ],
        CASHIER: [
            "dashboard.view",
            "billing", "billing.view", "billing.create",
            "invoices", "invoices.view", "invoices.create",
            "customers", "customers.view", "customers.create",
            "products.view",
            "inventory.view", "stock.view",
            "payments", "payments.view", "payments.create",
            "notifications.view",
        ],
        SALESPERSON: [
            "dashboard.view",
            "billing", "billing.view", "billing.create",
            "customers", "customers.view", "customers.create",
            "invoices", "invoices.view", "invoices.create",
            "payments", "payments.view", "payments.create",
            "products.view",
            "notifications.view",
        ],
        ACCOUNTANT: [
            "dashboard.view",
            "payments", "payments.view", "payments.create", "payments.edit",
            "purchases.view",
            "expenses", "expenses.view", "expenses.create", "expenses.edit",
            "ledger.customer", "ledger.supplier",
            "credit_debit.view", "credit_debit.create",
            "reports.view", "reports.profit_loss", "reports.gst",
            "invoices.view",
            "notifications.view",
        ],
        INVENTORY_MANAGER: [
            "dashboard.view",
            "products", "products.view", "products.create", "products.edit",
            "inventory", "inventory.view", "inventory.adjust", "inventory.transfer",
            "stock.view", "stock.manage", "stock.history",
            "purchases", "purchases.view", "purchases.create", "purchases.edit",
            "suppliers", "suppliers.view", "suppliers.create", "suppliers.edit",
            "returns.purchases",
            "reports.view", "reports.inventory",
            "notifications.view",
        ],
        STAFF: [
            "dashboard.view",
            "notifications.view",
        ],
    }

    @classmethod
    def normalize(cls, role_str):
        if not role_str:
            return cls.STAFF
        role_lower = str(role_str).strip().lower()
        mapping = {
            "owner": cls.OWNER,
            "admin": cls.ADMIN,
            "manager": cls.MANAGER,
            "cashier": cls.CASHIER,
            "salesperson": cls.SALESPERSON,
            "accountant": cls.ACCOUNTANT,
            "inventory manager": cls.INVENTORY_MANAGER,
            "inventory_manager": cls.INVENTORY_MANAGER,
            "staff": cls.STAFF,
        }
        return mapping.get(role_lower, cls.STAFF)

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    business_id = db.Column(db.Integer, db.ForeignKey("businesses.id"), nullable=True)
    branch_id = db.Column(db.Integer, db.ForeignKey("branches.id"), nullable=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    phone = db.Column(db.String(20), nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(50), default=Role.ADMIN, nullable=False)
    custom_permissions = db.Column(db.Text, nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def get_permissions(self):
        norm = Role.normalize(self.role)
        if norm in [Role.ADMIN, Role.OWNER]:
            return ["all"]
        base = list(Role.ROLE_PERMISSIONS.get(norm, []))
        if self.custom_permissions:
            try:
                custom = json.loads(self.custom_permissions)
                if isinstance(custom, list):
                    for p in custom:
                        if p and p not in base:
                            base.append(p)
            except Exception:
                for p in self.custom_permissions.split(","):
                    p = p.strip()
                    if p and p not in base:
                        base.append(p)
        return base

    def has_permission(self, permission):
        norm = Role.normalize(self.role)
        if norm in [Role.ADMIN, Role.OWNER]:
            return True
        perms = self.get_permissions()
        if "all" in perms:
            return True
        if permission in perms:
            return True
        if "." in permission:
            module = permission.split(".", 1)[0]
            if module in perms:
                return True
        return False

    def to_dict(self):
        return {
            "id": self.id,
            "business_id": self.business_id,
            "branch_id": self.branch_id,
            "name": self.name,
            "email": self.email,
            "phone": self.phone,
            "role": self.role,
            "is_active": self.is_active,
            "permissions": self.get_permissions(),
            "custom_permissions": self.custom_permissions,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
