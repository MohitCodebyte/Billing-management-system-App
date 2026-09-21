import pytest
import json
from app import create_app
from app.extensions import db
from app.models.user import User, Role
from app.models.business import Business, Branch
from app.utils.auth import generate_token

from app.config import TestConfig

@pytest.fixture
def client():
    app = create_app(TestConfig)

    with app.app_context():
        db.create_all()

        biz = Business(name="RBAC Industrial Test", gstin="27AAACB2234L1Z2", phone="9823012345")
        db.session.add(biz)
        db.session.flush()

        br = Branch(business_id=biz.id, name="Main Plant", code="MP-01")
        db.session.add(br)
        db.session.flush()

        # Admin
        admin = User(business_id=biz.id, branch_id=br.id, name="Admin User", email="admin@rbac.com", phone="9990011122", role=Role.ADMIN)
        admin.set_password("admin123")
        db.session.add(admin)

        # Cashier
        cashier = User(business_id=biz.id, branch_id=br.id, name="Cashier User", email="cashier@rbac.com", phone="9990011123", role=Role.CASHIER)
        cashier.set_password("cashier123")
        db.session.add(cashier)

        # Manager
        manager = User(business_id=biz.id, branch_id=br.id, name="Manager User", email="manager@rbac.com", phone="9990011124", role=Role.MANAGER)
        manager.set_password("manager123")
        db.session.add(manager)

        db.session.commit()

        with app.test_client() as test_client:
            yield test_client

        db.session.remove()
        db.drop_all()

def auth_header(token):
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

def test_admin_has_full_access(client):
    admin = User.query.filter_by(email="admin@rbac.com").first()
    token = generate_token(admin)
    headers = auth_header(token)

    # Admin can list employees
    res = client.get("/api/employees", headers=headers)
    assert res.status_code == 200

    # Admin can create branch
    res = client.post("/api/branches", headers=headers, json={"name": "Branch 2", "code": "BR-02"})
    assert res.status_code == 201

    # Admin can view business settings
    res = client.get("/api/settings/business", headers=headers)
    assert res.status_code == 200

def test_cashier_rbac_restrictions(client):
    cashier = User.query.filter_by(email="cashier@rbac.com").first()
    token = generate_token(cashier)
    headers = auth_header(token)

    # Cashier cannot view employees
    res = client.get("/api/employees", headers=headers)
    assert res.status_code == 403
    assert res.get_json().get("error_code") == "FORBIDDEN"

    # Cashier cannot create branch
    res = client.post("/api/branches", headers=headers, json={"name": "Forbidden Branch", "code": "FB-01"})
    assert res.status_code == 403

    # Cashier cannot view profit & loss
    res = client.get("/api/reports/profit-loss", headers=headers)
    assert res.status_code == 403

    # Cashier cannot view GST reports
    res = client.get("/api/reports/gst", headers=headers)
    assert res.status_code == 403

    # Cashier cannot view inventory reports
    res = client.get("/api/reports/inventory", headers=headers)
    assert res.status_code == 403

    # Cashier cannot create purchase
    res = client.post("/api/purchases", headers=headers, json={"supplier_id": 1})
    assert res.status_code == 403

    # Cashier cannot adjust stock
    res = client.post("/api/inventory/adjust", headers=headers, json={"product_id": 1, "quantity": 5})
    assert res.status_code == 403

    # Cashier cannot view business settings
    res = client.get("/api/settings/business", headers=headers)
    assert res.status_code == 403

    # Cashier CAN calculate billing (authorized)
    res = client.post("/api/billing/calculate", headers=headers, json={"items": []})
    assert res.status_code == 200

def test_custom_permission_grant_and_enforcement(client):
    admin = User.query.filter_by(email="admin@rbac.com").first()
    admin_token = generate_token(admin)

    # Admin creates a Cashier with additional 'reports.sales' permission
    res = client.post("/api/employees", headers=auth_header(admin_token), json={
        "name": "Trusted Cashier",
        "email": "trusted_cashier@rbac.com",
        "phone": "9876500001",
        "role": "Cashier",
        "password": "cashierpass123",
        "permissions": ["reports.sales"]
    })
    assert res.status_code == 201
    created_emp = res.get_json()["employee"]
    assert "reports.sales" in created_emp["permissions"]

    # Login as Trusted Cashier
    login_res = client.post("/api/auth/login", json={
        "email": "trusted_cashier@rbac.com",
        "password": "cashierpass123"
    })
    assert login_res.status_code == 200
    token = login_res.get_json()["token"]
    headers = auth_header(token)

    # Trusted Cashier CAN access sales reports
    sales_res = client.get("/api/reports/sales", headers=headers)
    assert sales_res.status_code == 200

    # But still CANNOT access profit-loss
    pl_res = client.get("/api/reports/profit-loss", headers=headers)
    assert pl_res.status_code == 403
