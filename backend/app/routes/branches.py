from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.business import Branch
from app.models.inventory import BranchStock
from app.models.product import Product
from app.models.user import Role
from app.utils.auth import token_required

branches_bp = Blueprint("branches", __name__, url_prefix="/api/branches")

@branches_bp.route("", methods=["GET"])
@token_required
def list_branches(current_user):
    branches = Branch.query.filter_by(business_id=current_user.business_id, is_active=True).all()
    return jsonify([b.to_dict() for b in branches])

@branches_bp.route("", methods=["POST"])
@token_required
def create_branch(current_user):
    if not (current_user.has_permission("branches.create") or current_user.has_permission("branches")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to create branches.",
            "error": "Only Admin can create branches",
            "error_code": "FORBIDDEN"
        }), 403

    data = request.get_json() or {}
    name = data.get("name")
    code = data.get("code")

    if not name or not code:
        return jsonify({"error": "Branch name and code are required"}), 400

    existing = Branch.query.filter_by(business_id=current_user.business_id, code=code).first()
    if existing:
        return jsonify({"error": f"Branch with code '{code}' already exists"}), 400

    branch = Branch(
        business_id=current_user.business_id,
        name=name,
        code=code,
        phone=data.get("phone", ""),
        email=data.get("email", ""),
        address=data.get("address", ""),
        city=data.get("city", ""),
        state=data.get("state", "Maharashtra"),
        gstin=data.get("gstin", ""),
        is_head_office=data.get("is_head_office", False)
    )
    db.session.add(branch)
    db.session.flush()

    # Initialize zero stock for all existing products for this branch
    products = Product.query.filter_by(business_id=current_user.business_id, is_active=True).all()
    for p in products:
        bs = BranchStock(branch_id=branch.id, product_id=p.id, quantity=0.0)
        db.session.add(bs)

    db.session.commit()
    return jsonify({
        "message": "Branch created successfully",
        "branch": branch.to_dict()
    }), 201

@branches_bp.route("/<int:branch_id>", methods=["PUT"])
@token_required
def update_branch(current_user, branch_id):
    if not (current_user.has_permission("branches.edit") or current_user.has_permission("branches")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to update branches.",
            "error": "Only Admin can update branches",
            "error_code": "FORBIDDEN"
        }), 403

    branch = Branch.query.filter_by(id=branch_id, business_id=current_user.business_id).first()
    if not branch:
        return jsonify({"error": "Branch not found"}), 404

    data = request.get_json() or {}
    branch.name = data.get("name", branch.name)
    branch.phone = data.get("phone", branch.phone)
    branch.email = data.get("email", branch.email)
    branch.address = data.get("address", branch.address)
    branch.city = data.get("city", branch.city)
    branch.state = data.get("state", branch.state)
    branch.gstin = data.get("gstin", branch.gstin)

    db.session.commit()
    return jsonify({
        "message": "Branch updated successfully",
        "branch": branch.to_dict()
    })

@branches_bp.route("/switch", methods=["POST"])
@token_required
def switch_active_branch(current_user):
    data = request.get_json() or {}
    branch_id = data.get("branch_id")

    branch = Branch.query.filter_by(id=branch_id, business_id=current_user.business_id).first()
    if not branch:
        return jsonify({"error": "Invalid branch"}), 404

    current_user.branch_id = branch.id
    db.session.commit()

    return jsonify({
        "message": f"Switched active branch to {branch.name}",
        "branch": branch.to_dict()
    })
