import json
import pytest
from app import create_app
from app.config import TestConfig
from app.extensions import db

@pytest.fixture
def client():
    app = create_app(TestConfig)
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.session.remove()
            db.drop_all()

def test_health_check_endpoint(client):
    res = client.get("/api/health")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["message"] == "API is running"
    assert "BharatLedger" in data["service"]
    assert "NexvoraTech LLP" in data["attribution"]

def test_cors_options_preflight(client):
    headers = {
        "Origin": "http://localhost:56314",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "Content-Type, Authorization"
    }
    res = client.options("/api/auth/login", headers=headers)
    assert res.status_code == 200
    assert "Access-Control-Allow-Origin" in res.headers
    assert res.headers["Access-Control-Allow-Origin"] == "*"

def test_auth_full_cycle(client):
    # 1. Register business
    reg_payload = {
        "name": "Precision Engineering Works",
        "owner_name": "Rohan Deshmukh",
        "email": "rohan@precisionworks.com",
        "phone": "+91 99887 76655",
        "password": "Password@123",
        "gstin": "27AAACB2234L1Z2",
        "address": "Plot 12, Bhosari MIDC",
        "city": "Pune"
    }
    res = client.post("/api/auth/register", json=reg_payload)
    assert res.status_code == 201
    data = res.get_json()
    assert "token" in data
    assert data["user"]["email"] == "rohan@precisionworks.com"

    # 2. Login
    login_payload = {
        "email": "rohan@precisionworks.com",
        "password": "Password@123"
    }
    res = client.post("/api/auth/login", json=login_payload)
    assert res.status_code == 200
    login_data = res.get_json()
    token = login_data["token"]
    assert token is not None

    # 3. Access current user info with Bearer token
    res = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    me_data = res.get_json()
    assert me_data["user"]["email"] == "rohan@precisionworks.com"

    # 4. OTP verification
    otp_res = client.post("/api/auth/send-otp", json={"phone": "+91 99887 76655"})
    assert otp_res.status_code == 200
    assert otp_res.get_json()["success"] is True

    verify_res = client.post("/api/auth/verify-otp", json={"phone": "+91 99887 76655", "otp": "1234"})
    assert verify_res.status_code == 200
    assert "token" in verify_res.get_json()

    # 5. Logout
    logout_res = client.post("/api/auth/logout")
    assert logout_res.status_code == 200

def test_admin_and_cashier_roles_and_permissions(client):
    from app.models.user import User, Role
    from app.models.business import Business, Branch

    # Create business and branch
    biz = Business(name="Industrial Test Co", email="test@ind.com", phone="+91 98000 00000")
    db.session.add(biz)
    db.session.flush()

    branch = Branch(business_id=biz.id, name="Test Branch", code="TB-01", phone="+91 98000 00000", email="b@ind.com")
    db.session.add(branch)
    db.session.flush()

    # Seed Admin and Cashier
    admin = User(business_id=biz.id, branch_id=branch.id, name="Admin User", email="admin@bharatledger.com", phone="+91 98000 11111", role=Role.ADMIN)
    admin.set_password("admin123")

    cashier = User(business_id=biz.id, branch_id=branch.id, name="Cashier User", email="cashier@bharatledger.com", phone="+91 98000 22222", role=Role.CASHIER)
    cashier.set_password("cashier123")

    db.session.add_all([admin, cashier])
    db.session.commit()

    # 1. Admin Login
    admin_login = client.post("/api/auth/login", json={"email": "admin@bharatledger.com", "password": "admin123"})
    assert admin_login.status_code == 200
    admin_data = admin_login.get_json()
    assert admin_data["user"]["role"] == "Admin"
    assert "all" in admin_data["permissions"]
    admin_token = admin_data["token"]

    # 2. Cashier Login
    cashier_login = client.post("/api/auth/login", json={"email": "cashier@bharatledger.com", "password": "cashier123"})
    assert cashier_login.status_code == 200
    cashier_data = cashier_login.get_json()
    assert cashier_data["user"]["role"] == "Cashier"
    assert "billing" in cashier_data["permissions"]
    cashier_token = cashier_data["token"]

    # 3. Cashier attempting Admin-only endpoint (POST /api/employees) MUST return 403 Forbidden
    unauthorized_res = client.post("/api/employees",
        headers={"Authorization": f"Bearer {cashier_token}"},
        json={"name": "Hacker", "email": "hacker@domain.com", "phone": "123", "role": "admin"}
    )
    assert unauthorized_res.status_code == 403
    assert "Only Admin" in unauthorized_res.get_json()["error"]

    # 4. Admin creating a new employee succeeds
    new_emp_res = client.post("/api/employees",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": "Suresh Sales", "email": "suresh@bharatledger.com", "phone": "+91 98765 43210", "role": "salesperson"}
    )
    assert new_emp_res.status_code == 201
    assert new_emp_res.get_json()["employee"]["role"] == "Salesperson"

    # 5. Invite employee
    emp_id = new_emp_res.get_json()["employee"]["id"]
    invite_res = client.post(f"/api/employees/{emp_id}/invite", headers={"Authorization": f"Bearer {admin_token}"})
    assert invite_res.status_code == 200
    assert invite_res.get_json()["success"] is True

    # 6. Activate employee account with custom password
    activate_res = client.post("/api/auth/activate", json={
        "email": "suresh@bharatledger.com",
        "password": "SureshPassword@123"
    })
    assert activate_res.status_code == 200
    assert activate_res.get_json()["success"] is True

    # 7. Activated employee can now log in
    emp_login = client.post("/api/auth/login", json={
        "email": "suresh@bharatledger.com",
        "password": "SureshPassword@123"
    })
    assert emp_login.status_code == 200
    assert emp_login.get_json()["user"]["role"] == "Salesperson"

def test_negative_authentication(client):
    # Wrong password
    res = client.post("/api/auth/login", json={"email": "admin@bharatledger.com", "password": "wrongpassword"})
    assert res.status_code == 401
    assert "Invalid email or password" in res.get_json()["error"]

    # Unknown user
    res = client.post("/api/auth/login", json={"email": "nobody@nowhere.com", "password": "password"})
    assert res.status_code == 401
    assert "Invalid email or password" in res.get_json()["error"]

    # Missing credentials
    res = client.post("/api/auth/login", json={})
    assert res.status_code == 400

