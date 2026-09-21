import pytest
from app import create_app
from app.config import TestConfig
from app.extensions import db
from app.models.user import User, Role
from app.models.business import Business, Branch, BusinessSettings
from app.models.party import Customer
from app.models.product import Product
from app.models.inventory import BranchStock
from app.models.invoice import Invoice
from app.models.ledger import CustomerLedgerEntry
from app.services.billing_service import BillingService

@pytest.fixture
def app():
    app = create_app(TestConfig)
    with app.app_context():
        # Setup initial test database entities
        biz = Business(name="Test Industrial Corp", phone="9999999999", gstin="27AAACT1234L1Z1", state="Maharashtra")
        db.session.add(biz)
        db.session.flush()

        branch = Branch(business_id=biz.id, name="Main Warehouse", code="WH-01", is_head_office=True, state="Maharashtra")
        db.session.add(branch)
        db.session.flush()

        settings = BusinessSettings(business_id=biz.id, invoice_prefix="TEST-INV-", next_invoice_number=1)
        db.session.add(settings)

        admin = User(business_id=biz.id, branch_id=branch.id, name="Tester", email="test@test.com", phone="9999999999", role=Role.ADMIN)
        admin.set_password("pass123")
        db.session.add(admin)

        cust = Customer(business_id=biz.id, name="Test Customer", phone="8888888888", state="Maharashtra", credit_limit=50000.0)
        db.session.add(cust)

        prod = Product(
            business_id=biz.id,
            name="Industrial Valve 2 Inch",
            sku="VAL-001",
            selling_price=1000.0,
            purchase_price=700.0,
            mrp=1200.0,
            gst_rate=18.0,
            unit="PCS"
        )
        db.session.add(prod)
        db.session.flush()

        stock = BranchStock(branch_id=branch.id, product_id=prod.id, quantity=50.0)
        db.session.add(stock)

        db.session.commit()
        yield app

def test_atomic_billing_workflow(app):
    with app.app_context():
        biz = Business.query.first()
        branch = Branch.query.first()
        cust = Customer.query.first()
        prod = Product.query.first()
        admin = User.query.first()

        initial_stock = prod.get_stock(branch.id)
        assert initial_stock == 50.0
        assert cust.current_balance == 0.0

        # Create Invoice for 2 items @ 1000 = 2000 taxable. 18% GST = 360. Grand Total = 2360.
        # Partial payment = 1000. Balance = 1360.
        invoice_data = {
            "business_id": biz.id,
            "branch_id": branch.id,
            "customer_id": cust.id,
            "items": [
                {
                    "product_id": prod.id,
                    "quantity": 2.0,
                    "unit_price": 1000.0,
                    "gst_rate": 18.0
                }
            ],
            "payment": {
                "amount": 1000.0,
                "payment_method": "CASH"
            }
        }

        invoice = BillingService.create_invoice(invoice_data, user_id=admin.id)

        assert invoice.grand_total == 2360.0
        assert invoice.paid_amount == 1000.0
        assert invoice.balance_amount == 1360.0
        assert invoice.status == "PARTIAL"

        # 1. Verify stock decreased by 2 units
        new_stock = prod.get_stock(branch.id)
        assert new_stock == 48.0

        # 2. Verify Customer current balance is updated (2360 debit - 1000 credit = 1360)
        db.session.refresh(cust)
        assert cust.current_balance == 1360.0

        # 3. Verify Customer Ledger entries
        entries = CustomerLedgerEntry.query.filter_by(customer_id=cust.id).order_by(CustomerLedgerEntry.id.asc()).all()
        assert len(entries) == 2
        assert entries[0].voucher_type == "INVOICE"
        assert entries[0].debit_amount == 2360.0
        assert entries[1].voucher_type == "PAYMENT"
        assert entries[1].credit_amount == 1000.0
        assert entries[1].running_balance == 1360.0
