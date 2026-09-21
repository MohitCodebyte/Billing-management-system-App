import json
from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.user import User, Role
from app.utils.auth import token_required

employees_bp = Blueprint("employees", __name__, url_prefix="/api/employees")

@employees_bp.route("", methods=["GET"])
@token_required
def list_employees(current_user):
    if not (current_user.has_permission("employees.view") or current_user.has_permission("employees")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view employees.",
            "error": "Only Admin or Manager can view employees",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    query = User.query.filter_by(business_id=current_user.business_id, is_active=True)
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    users = query.all()
    return jsonify([u.to_dict() for u in users])

@employees_bp.route("", methods=["POST"])
@token_required
def create_employee(current_user):
    if not (current_user.has_permission("employees.create") or current_user.has_permission("employees")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to add employees.",
            "error": "Only Admin can add employees",
            "error_code": "FORBIDDEN"
        }), 403

    data = request.get_json() or {}
    name = data.get("name")
    email = data.get("email")
    phone = data.get("phone")
    password = data.get("password") or "Employee@123"
    role = Role.normalize(data.get("role", Role.STAFF))

    if not name or not email or not phone:
        return jsonify({"error": "Name, email, and phone are required"}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({"error": "User with this email already exists"}), 400

    user = User(
        business_id=current_user.business_id,
        branch_id=data.get("branch_id", current_user.branch_id),
        name=name,
        email=email,
        phone=phone,
        role=role,
        is_active=True
    )
    custom_perms = data.get("permissions")
    if custom_perms is not None and isinstance(custom_perms, list):
        user.custom_permissions = json.dumps(custom_perms)

    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    return jsonify({
        "success": True,
        "message": "Employee created successfully",
        "employee": user.to_dict()
    }), 201

@employees_bp.route("/<int:user_id>/invite", methods=["POST"])
@token_required
def invite_employee(current_user, user_id):
    if not (current_user.has_permission("employees.create") or current_user.has_permission("employees")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to send invitations.",
            "error": "Only Admin can send employee invitations",
            "error_code": "FORBIDDEN"
        }), 403

    user = User.query.filter_by(id=user_id, business_id=current_user.business_id).first()
    if not user:
        return jsonify({"error": "Employee not found"}), 404

    return jsonify({
        "success": True,
        "message": f"Invitation dispatched to {user.email}",
        "activation_code": "ACT-1234",
        "employee": user.to_dict()
    }), 200

@employees_bp.route("/<int:user_id>", methods=["PUT"])
@token_required
def update_employee(current_user, user_id):
    if not (current_user.has_permission("employees.edit") or current_user.has_permission("employees")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to update employees.",
            "error": "Only Admin can update employees",
            "error_code": "FORBIDDEN"
        }), 403

    user = User.query.filter_by(id=user_id, business_id=current_user.business_id).first()
    if not user:
        return jsonify({"error": "Employee not found"}), 404

    data = request.get_json() or {}
    user.name = data.get("name", user.name)
    user.phone = data.get("phone", user.phone)
    if "role" in data:
        user.role = Role.normalize(data["role"])
    if "branch_id" in data:
        user.branch_id = data["branch_id"]
    if "password" in data and data["password"]:
        user.set_password(data["password"])
    if "permissions" in data:
        perms = data["permissions"]
        if isinstance(perms, list):
            user.custom_permissions = json.dumps(perms)
        elif perms is None:
            user.custom_permissions = None

    db.session.commit()
    return jsonify({
        "success": True,
        "message": "Employee updated successfully",
        "employee": user.to_dict()
    })

@employees_bp.route("/<int:user_id>", methods=["DELETE"])
@token_required
def delete_employee(current_user, user_id):
    if not (current_user.has_permission("employees.disable") or current_user.has_permission("employees")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to deactivate employees.",
            "error": "Only Admin can deactivate employees",
            "error_code": "FORBIDDEN"
        }), 403

    user = User.query.filter_by(id=user_id, business_id=current_user.business_id).first()
    if not user:
        return jsonify({"error": "Employee not found"}), 404

    user.is_active = False
    db.session.commit()
    return jsonify({"success": True, "message": "Employee deactivated successfully"})
