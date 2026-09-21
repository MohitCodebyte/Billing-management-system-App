from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.party import Supplier
from app.models.ledger import SupplierLedgerEntry
from app.models.purchase import Purchase
from app.utils.auth import token_required

suppliers_bp = Blueprint("suppliers", __name__, url_prefix="/api/suppliers")

@suppliers_bp.route("", methods=["GET"])
@token_required
def list_suppliers(current_user):
    if not (current_user.has_permission("suppliers.view") or current_user.has_permission("suppliers")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view suppliers.",
            "error": "Permission denied for 'suppliers.view'",
            "error_code": "FORBIDDEN"
        }), 403

    search = request.args.get("search")
    query = Supplier.query.filter_by(business_id=current_user.business_id, is_active=True)

    if search:
        query = query.filter(
            db.or_(
                Supplier.name.ilike(f"%{search}%"),
                Supplier.company_name.ilike(f"%{search}%"),
                Supplier.phone.ilike(f"%{search}%"),
                Supplier.gstin.ilike(f"%{search}%")
            )
        )

    suppliers = query.order_by(Supplier.name.asc()).all()
    return jsonify([s.to_dict() for s in suppliers])

@suppliers_bp.route("/<int:supplier_id>", methods=["GET"])
@token_required
def get_supplier(current_user, supplier_id):
    if not (current_user.has_permission("suppliers.view") or current_user.has_permission("suppliers")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view suppliers.",
            "error": "Permission denied for 'suppliers.view'",
            "error_code": "FORBIDDEN"
        }), 403

    supplier = Supplier.query.filter_by(id=supplier_id, business_id=current_user.business_id).first()
    if not supplier:
        return jsonify({"error": "Supplier not found"}), 404

    purchases = Purchase.query.filter_by(supplier_id=supplier.id).order_by(Purchase.created_at.desc()).limit(10).all()
    ledger = SupplierLedgerEntry.query.filter_by(supplier_id=supplier.id).order_by(SupplierLedgerEntry.created_at.desc()).limit(20).all()

    data = supplier.to_dict()
    data["recent_purchases"] = [p.to_dict() for p in purchases]
    data["ledger_entries"] = [entry.to_dict() for entry in ledger]
    return jsonify(data)

@suppliers_bp.route("", methods=["POST"])
@token_required
def create_supplier(current_user):
    if not (current_user.has_permission("suppliers.create") or current_user.has_permission("suppliers")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to create suppliers.",
            "error": "Permission denied for 'suppliers.create'",
            "error_code": "FORBIDDEN"
        }), 403

    data = request.get_json() or {}
    name = data.get("name")
    phone = data.get("phone")

    if not name or not phone:
        return jsonify({"error": "Supplier name and phone are required"}), 400

    opening_balance = float(data.get("opening_balance", 0.0))

    supplier = Supplier(
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
        opening_balance=opening_balance,
        current_payable=opening_balance
    )
    db.session.add(supplier)
    db.session.flush()

    if opening_balance != 0:
        entry = SupplierLedgerEntry(
            business_id=current_user.business_id,
            supplier_id=supplier.id,
            voucher_type="OPENING_BALANCE",
            voucher_number="OP-BAL",
            debit_amount=abs(opening_balance) if opening_balance < 0 else 0.0,
            credit_amount=opening_balance if opening_balance > 0 else 0.0,
            running_balance=opening_balance,
            narration="Opening Balance"
        )
        db.session.add(entry)

    db.session.commit()
    return jsonify({
        "message": "Supplier created successfully",
        "supplier": supplier.to_dict()
    }), 201

@suppliers_bp.route("/<int:supplier_id>", methods=["PUT"])
@token_required
def update_supplier(current_user, supplier_id):
    if not (current_user.has_permission("suppliers.edit") or current_user.has_permission("suppliers")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to update suppliers.",
            "error": "Permission denied for 'suppliers.edit'",
            "error_code": "FORBIDDEN"
        }), 403

    supplier = Supplier.query.filter_by(id=supplier_id, business_id=current_user.business_id).first()
    if not supplier:
        return jsonify({"error": "Supplier not found"}), 404

    data = request.get_json() or {}
    supplier.name = data.get("name", supplier.name)
    supplier.company_name = data.get("company_name", supplier.company_name)
    supplier.phone = data.get("phone", supplier.phone)
    supplier.email = data.get("email", supplier.email)
    supplier.gstin = data.get("gstin", supplier.gstin)
    supplier.pan = data.get("pan", supplier.pan)
    supplier.address = data.get("address", supplier.address)
    supplier.city = data.get("city", supplier.city)
    supplier.state = data.get("state", supplier.state)
    supplier.pincode = data.get("pincode", supplier.pincode)

    db.session.commit()
    return jsonify({
        "message": "Supplier updated successfully",
        "supplier": supplier.to_dict()
    })

@suppliers_bp.route("/<int:supplier_id>", methods=["DELETE"])
@token_required
def delete_supplier(current_user, supplier_id):
    if not (current_user.has_permission("suppliers.delete") or current_user.has_permission("suppliers")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to delete suppliers.",
            "error": "Permission denied for 'suppliers.delete'",
            "error_code": "FORBIDDEN"
        }), 403

    supplier = Supplier.query.filter_by(id=supplier_id, business_id=current_user.business_id).first()
    if not supplier:
        return jsonify({"error": "Supplier not found"}), 404

    supplier.is_active = False
    db.session.commit()
    return jsonify({"message": "Supplier deactivated successfully"})
