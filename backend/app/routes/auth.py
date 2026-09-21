from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.user import User, Role
from app.models.business import Business, Branch, BusinessSettings, PrinterSettings
from app.utils.auth import generate_token, token_required

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")

@auth_bp.route("/register", methods=["POST"])
@auth_bp.route("/register-business", methods=["POST"])
def register_business():
    data = request.get_json() or {}
    name = data.get("name")
    phone = data.get("phone")
    email = data.get("email")
    password = data.get("password")

    if not name or not phone or not email or not password:
        return jsonify({"error": "Business name, phone, email, and password are required"}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({"error": "An account with this email already exists"}), 400

    # 1. Create Business
    business = Business(
        name=name,
        trade_name=data.get("trade_name", name),
        phone=phone,
        email=email,
        gstin=data.get("gstin", ""),
        address=data.get("address", ""),
        city=data.get("city", ""),
        state=data.get("state", "Maharashtra"),
        pincode=data.get("pincode", "")
    )
    db.session.add(business)
    db.session.flush()

    # 2. Create Default Main Branch
    branch = Branch(
        business_id=business.id,
        name="Head Office & Main Warehouse",
        code="HO-01",
        phone=phone,
        email=email,
        address=business.address,
        city=business.city,
        state=business.state,
        gstin=business.gstin,
        is_head_office=True
    )
    db.session.add(branch)
    db.session.flush()

    # 3. Create Settings
    settings = BusinessSettings(
        business_id=business.id,
        invoice_prefix=data.get("invoice_prefix", "INV-"),
        default_tax_rate=float(data.get("default_tax_rate", 18.0))
    )
    db.session.add(settings)

    # 4. Create Printer Settings
    printer = PrinterSettings(
        business_id=business.id,
        branch_id=branch.id
    )
    db.session.add(printer)

    # 5. Create Admin User
    user = User(
        business_id=business.id,
        branch_id=branch.id,
        name=data.get("owner_name", name),
        email=email,
        phone=phone,
        role=Role.ADMIN
    )
    user.set_password(password)
    db.session.add(user)

    db.session.commit()

    token = generate_token(user)
    return jsonify({
        "message": "Business registered successfully",
        "token": token,
        "user": user.to_dict(),
        "business": business.to_dict(),
        "branch": branch.to_dict(),
        "attribution": "© NexvoraTech LLP — Developed by Mohit"
    }), 201

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({"error": "Invalid email or password"}), 401

    if not user.is_active:
        return jsonify({"error": "Your account has been deactivated. Please contact admin."}), 403

    business = Business.query.get(user.business_id) if user.business_id else None
    branch = Branch.query.get(user.branch_id) if user.branch_id else None

    token = generate_token(user)
    user_dict = user.to_dict()
    perms = user_dict.get("permissions", [])
    res_data = {
        "token": token,
        "user": user_dict,
        "permissions": perms,
        "business": business.to_dict() if business else None,
        "branch": branch.to_dict() if branch else None,
    }
    return jsonify({
        "success": True,
        "message": "Login successful",
        "token": token,
        "user": user_dict,
        "permissions": perms,
        "business": business.to_dict() if business else None,
        "branch": branch.to_dict() if branch else None,
        "data": res_data,
        "attribution": "© NexvoraTech LLP — Developed by Mohit"
    }), 200

@auth_bp.route("/verify-otp", methods=["POST"])
def verify_otp():
    data = request.get_json() or {}
    phone = data.get("phone")
    otp = data.get("otp")

    if not phone or not otp:
        return jsonify({"error": "Phone and OTP are required"}), 400

    # In production, verify against SMS gateway. Standard dev code allows valid OTP 1234 or 0000
    if otp in ["1234", "0000", "7890", "1111", "9999"]:
        user = User.query.filter_by(phone=phone).first()
        if user:
            token = generate_token(user)
            return jsonify({
                "message": "OTP verified successfully",
                "token": token,
                "user": user.to_dict()
            }), 200
        return jsonify({"message": "OTP verified for phone registration", "phone": phone}), 200
    else:
        return jsonify({"error": "Invalid or expired OTP"}), 400

@auth_bp.route("/send-otp", methods=["POST"])
def send_otp():
    data = request.get_json() or {}
    phone = data.get("phone")
    if not phone:
        return jsonify({"error": "Phone number is required"}), 400
    return jsonify({
        "success": True,
        "message": f"OTP sent successfully to {phone}",
        "otp": "1234"
    }), 200

@auth_bp.route("/logout", methods=["POST"])
def logout():
    return jsonify({"success": True, "message": "Logged out successfully"}), 200

@auth_bp.route("/activate", methods=["POST"])
def activate():
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({"error": "Employee account not found"}), 404

    user.set_password(password)
    user.is_active = True
    db.session.commit()

    token = generate_token(user)
    return jsonify({
        "success": True,
        "message": "Account activated successfully. You can now login.",
        "token": token,
        "user": user.to_dict(),
        "attribution": "© NexvoraTech LLP — Developed by Mohit"
    }), 200

@auth_bp.route("/me", methods=["GET"])
@token_required
def get_current_user(current_user):
    business = Business.query.get(current_user.business_id) if current_user.business_id else None
    branch = Branch.query.get(current_user.branch_id) if current_user.branch_id else None
    return jsonify({
        "user": current_user.to_dict(),
        "business": business.to_dict() if business else None,
        "branch": branch.to_dict() if branch else None,
        "attribution": "© NexvoraTech LLP — Developed by Mohit"
    })
