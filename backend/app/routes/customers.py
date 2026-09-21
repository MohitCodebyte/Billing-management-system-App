from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.party import Customer
from app.models.ledger import CustomerLedgerEntry
from app.models.invoice import Invoice
from app.utils.auth import token_required

customers_bp = Blueprint("customers", __name__, url_prefix="/api/customers")

@customers_bp.route("", methods=["GET"])
@token_required
def list_customers(current_user):
    search = request.args.get("search")
    query = Customer.query.filter_by(business_id=current_user.business_id, is_active=True)

    if search:
        query = query.filter(
            db.or_(
                Customer.name.ilike(f"%{search}%"),
                Customer.company_name.ilike(f"%{search}%"),
                Customer.phone.ilike(f"%{search}%"),
                Customer.gstin.ilike(f"%{search}%")
            )
        )

    customers = query.order_by(Customer.name.asc()).all()
    return jsonify([c.to_dict() for c in customers])

@customers_bp.route("/<int:customer_id>", methods=["GET"])
@token_required
def get_customer(current_user, customer_id):
    customer = Customer.query.filter_by(id=customer_id, business_id=current_user.business_id).first()
    if not customer:
        return jsonify({"error": "Customer not found"}), 404

    invoices = Invoice.query.filter_by(customer_id=customer.id).order_by(Invoice.created_at.desc()).limit(10).all()
    ledger = CustomerLedgerEntry.query.filter_by(customer_id=customer.id).order_by(CustomerLedgerEntry.created_at.desc()).limit(20).all()

    data = customer.to_dict()
    data["recent_invoices"] = [inv.to_dict() for inv in invoices]
    data["ledger_entries"] = [entry.to_dict() for entry in ledger]
    return jsonify(data)

@customers_bp.route("", methods=["POST"])
@token_required
def create_customer(current_user):
    data = request.get_json() or {}
    name = data.get("name")
    phone = data.get("phone")

    if not name or not phone:
        return jsonify({"error": "Customer name and phone are required"}), 400

    opening_balance = float(data.get("opening_balance", 0.0))

    customer = Customer(
        business_id=current_user.business_id,
        name=name,
        company_name=data.get("company_name", ""),
        phone=phone,
        email=data.get("email", ""),
        gstin=data.get("gstin", ""),
        pan=data.get("pan", ""),
        address=data.get("address", ""),
        city=data.get("city", ""),
        state=data.get("state", "Maharashtra"),
        pincode=data.get("pincode", ""),
        credit_limit=float(data.get("credit_limit", 100000.0)),
        opening_balance=opening_balance,
        current_balance=opening_balance
    )
    db.session.add(customer)
    db.session.flush()

    if opening_balance != 0:
        entry = CustomerLedgerEntry(
            business_id=current_user.business_id,
            customer_id=customer.id,
            voucher_type="OPENING_BALANCE",
            voucher_number="OP-BAL",
            debit_amount=opening_balance if opening_balance > 0 else 0.0,
            credit_amount=abs(opening_balance) if opening_balance < 0 else 0.0,
            running_balance=opening_balance,
            narration="Opening Balance"
        )
        db.session.add(entry)

    db.session.commit()
    return jsonify({
        "message": "Customer created successfully",
        "customer": customer.to_dict()
    }), 201

@customers_bp.route("/<int:customer_id>", methods=["PUT"])
@token_required
def update_customer(current_user, customer_id):
    customer = Customer.query.filter_by(id=customer_id, business_id=current_user.business_id).first()
    if not customer:
        return jsonify({"error": "Customer not found"}), 404

    data = request.get_json() or {}
    customer.name = data.get("name", customer.name)
    customer.company_name = data.get("company_name", customer.company_name)
    customer.phone = data.get("phone", customer.phone)
    customer.email = data.get("email", customer.email)
    customer.gstin = data.get("gstin", customer.gstin)
    customer.pan = data.get("pan", customer.pan)
    customer.address = data.get("address", customer.address)
    customer.city = data.get("city", customer.city)
    customer.state = data.get("state", customer.state)
    customer.pincode = data.get("pincode", customer.pincode)
    if "credit_limit" in data:
        customer.credit_limit = float(data["credit_limit"])

    db.session.commit()
    return jsonify({
        "message": "Customer updated successfully",
        "customer": customer.to_dict()
    })

@customers_bp.route("/<int:customer_id>", methods=["DELETE"])
@token_required
def delete_customer(current_user, customer_id):
    customer = Customer.query.filter_by(id=customer_id, business_id=current_user.business_id).first()
    if not customer:
        return jsonify({"error": "Customer not found"}), 404

    customer.is_active = False
    db.session.commit()
    return jsonify({"message": "Customer deactivated successfully"})
