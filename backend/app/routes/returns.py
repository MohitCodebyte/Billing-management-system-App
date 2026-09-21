from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.return_order import SalesReturn, PurchaseReturn
from app.services.return_service import ReturnService
from app.utils.auth import token_required

returns_bp = Blueprint("returns", __name__, url_prefix="/api/returns")

@returns_bp.route("/sales", methods=["GET"])
@token_required
def list_sales_returns(current_user):
    branch_id = request.args.get("branch_id", type=int)
    query = SalesReturn.query.filter_by(business_id=current_user.business_id)
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    returns = query.order_by(SalesReturn.created_at.desc()).all()
    return jsonify([r.to_dict() for r in returns])

@returns_bp.route("/sales", methods=["POST"])
@token_required
def create_sales_return(current_user):
    data = request.get_json() or {}
    data["business_id"] = current_user.business_id
    if "branch_id" not in data or not data["branch_id"]:
        data["branch_id"] = current_user.branch_id

    try:
        ret = ReturnService.process_sales_return(data, user_id=current_user.id)
        return jsonify({
            "message": "Sales return processed successfully",
            "return": ret.to_dict()
        }), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to process sales return: {str(e)}"}), 500

@returns_bp.route("/purchases", methods=["GET"])
@token_required
def list_purchase_returns(current_user):
    branch_id = request.args.get("branch_id", type=int)
    query = PurchaseReturn.query.filter_by(business_id=current_user.business_id)
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    returns = query.order_by(PurchaseReturn.created_at.desc()).all()
    return jsonify([r.to_dict() for r in returns])

@returns_bp.route("/purchases", methods=["POST"])
@token_required
def create_purchase_return(current_user):
    data = request.get_json() or {}
    data["business_id"] = current_user.business_id
    if "branch_id" not in data or not data["branch_id"]:
        data["branch_id"] = current_user.branch_id

    try:
        ret = ReturnService.process_purchase_return(data, user_id=current_user.id)
        return jsonify({
            "message": "Purchase return processed successfully",
            "return": ret.to_dict()
        }), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to process purchase return: {str(e)}"}), 500
