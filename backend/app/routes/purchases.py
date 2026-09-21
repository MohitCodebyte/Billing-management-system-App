from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.purchase import Purchase
from app.services.purchase_service import PurchaseService
from app.utils.auth import token_required

purchases_bp = Blueprint("purchases", __name__, url_prefix="/api/purchases")

@purchases_bp.route("", methods=["POST"])
@token_required
def create_purchase(current_user):
    if not (current_user.has_permission("purchases.create") or current_user.has_permission("purchases")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to create purchases.",
            "error": "Permission denied for 'purchases.create'",
            "error_code": "FORBIDDEN"
        }), 403

    data = request.get_json() or {}
    data["business_id"] = current_user.business_id
    if "branch_id" not in data or not data["branch_id"]:
        data["branch_id"] = current_user.branch_id

    try:
        purchase = PurchaseService.create_purchase(data, user_id=current_user.id)
        return jsonify({
            "message": "Purchase created and stock updated successfully",
            "purchase": purchase.to_dict()
        }), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to create purchase: {str(e)}"}), 500

@purchases_bp.route("", methods=["GET"])
@token_required
def list_purchases(current_user):
    if not (current_user.has_permission("purchases.view") or current_user.has_permission("purchases")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view purchases.",
            "error": "Permission denied for 'purchases.view'",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    supplier_id = request.args.get("supplier_id", type=int)
    search = request.args.get("search")

    query = Purchase.query.filter_by(business_id=current_user.business_id)

    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if supplier_id:
        query = query.filter_by(supplier_id=supplier_id)
    if search:
        query = query.filter(Purchase.purchase_number.ilike(f"%{search}%"))

    purchases = query.order_by(Purchase.created_at.desc()).all()
    return jsonify([p.to_dict() for p in purchases])

@purchases_bp.route("/<int:purchase_id>", methods=["GET"])
@token_required
def get_purchase(current_user, purchase_id):
    if not (current_user.has_permission("purchases.view") or current_user.has_permission("purchases")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view purchases.",
            "error": "Permission denied for 'purchases.view'",
            "error_code": "FORBIDDEN"
        }), 403

    purchase = Purchase.query.filter_by(id=purchase_id, business_id=current_user.business_id).first()
    if not purchase:
        return jsonify({"error": "Purchase not found"}), 404
    return jsonify(purchase.to_dict())
