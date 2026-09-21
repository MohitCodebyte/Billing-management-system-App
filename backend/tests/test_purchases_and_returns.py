import pytest
from app import create_app
from app.config import TestConfig
from app.extensions import db
from app.models.user import User, Role
from app.models.business import Business, Branch, BusinessSettings
from app.models.party import Supplier, Customer
from app.models.product import Product
from app.models.inventory import BranchStock
from app.models.ledger import SupplierLedgerEntry
from app.services.purchase_service import PurchaseService
from app.services.billing_service import BillingService
from app.services.return_service import ReturnService

@pytest.fixture
def app():
    app = create_app(TestConfig)
    with app.app_context():
        biz = Business(name="Test Industrial Corp", phone="9999999999", gstin="27AAACT1234L1Z1", state="Maharashtra")
        db.session.add(biz)
        db.session.flush()

        branch = Branch(business_id=biz.id, name="Main Warehouse", code="WH-01", is_head_office=True, state="Maharashtra")
        db.session.add(branch)
        db.session.flush()

        settings = BusinessSettings(business_id=biz.id, purchase_prefix="TEST-PO-", next_purchase_number=1, invoice_prefix="INV-")
        db.session.add(settings)

        admin = User(business_id=biz.id, branch_id=branch.id, name="Tester", email="test@test.com", phone="9999999999", role=Role.ADMIN)
        admin.set_password("pass123")
        db.session.add(admin)

        sup = Supplier(business_id=biz.id, name="Steel Supplier Ltd", phone="7777777777", state="Maharashtra")
        db.session.add(sup)

        cust = Customer(business_id=biz.id, name="Cust A", phone="8888888888", state="Maharashtra")
        db.session.add(cust)

        prod = Product(
            business_id=biz.id,
            name="MS Flange 2 Inch",
            sku="FLG-002",
            selling_price=500.0,
            purchase_price=300.0,
            mrp=600.0,
            gst_rate=18.0,
            unit="PCS"
        )
        db.session.add(prod)
        db.session.flush()

        stock = BranchStock(branch_id=branch.id, product_id=prod.id, quantity=10.0)
        db.session.add(stock)

        db.session.commit()
        yield app

def test_purchase_and_return_workflow(app):
    with app.app_context():
        biz = Business.query.first()
        branch = Branch.query.first()
        sup = Supplier.query.first()
        cust = Customer.query.first()
        prod = Product.query.first()
        admin = User.query.first()

        # Initial stock: 10
        assert prod.get_stock(branch.id) == 10.0

        # 1. Purchase 20 units @ 300 = 6000 + 18% GST = 7080. Paid 7080 in full.
        pur_data = {
            "business_id": biz.id,
            "branch_id": branch.id,
            "supplier_id": sup.id,
            "items": [
                {
                    "product_id": prod.id,
                    "quantity": 20.0,
                    "unit_price": 300.0,
                    "gst_rate": 18.0
                }
            ],
            "payment": {
                "amount": 7080.0,
                "payment_method": "BANK_TRANSFER"
            }
        }
        purchase = PurchaseService.create_purchase(pur_data, user_id=admin.id)
        assert purchase.grand_total == 7080.0
        assert purchase.status == "PAID"

        # Stock should increase to 10 + 20 = 30
        assert prod.get_stock(branch.id) == 30.0

        # Supplier ledger entries
        entries = SupplierLedgerEntry.query.filter_by(supplier_id=sup.id).all()
        assert len(entries) == 2
        assert entries[0].voucher_type == "PURCHASE"
        assert entries[0].credit_amount == 7080.0
        assert entries[1].voucher_type == "PAYMENT"
        assert entries[1].debit_amount == 7080.0
        assert entries[1].running_balance == 0.0

        # 2. Test Sales Invoice & Return
        inv_data = {
            "business_id": biz.id,
            "branch_id": branch.id,
            "customer_id": cust.id,
            "items": [{"product_id": prod.id, "quantity": 5.0, "unit_price": 500.0, "gst_rate": 18.0}],
            "payment": {"amount": 2950.0, "payment_method": "CASH"}
        }
        invoice = BillingService.create_invoice(inv_data, user_id=admin.id)
        assert prod.get_stock(branch.id) == 25.0

        # Sales return 2 units
        ret_data = {
            "business_id": biz.id,
            "branch_id": branch.id,
            "invoice_id": invoice.id,
            "items": [
                {
                    "product_id": prod.id,
                    "product_name": prod.name,
                    "quantity": 2.0,
                    "unit_price": 500.0,
                    "restock_inventory": True
                }
            ],
            "refund_type": "CREDIT_NOTE",
            "reason": "Wrong size ordered by customer"
        }
        s_return = ReturnService.process_sales_return(ret_data, user_id=admin.id)
        assert s_return.total_amount == 1000.0

        # Stock should replenish by 2 units -> 25 + 2 = 27
        assert prod.get_stock(branch.id) == 27.0
