from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.expense import Expense, ExpenseCategory
from app.utils.auth import token_required

expenses_bp = Blueprint("expenses", __name__, url_prefix="/api/expenses")

@expenses_bp.route("", methods=["GET"])
@token_required
def list_expenses(current_user):
    if not (current_user.has_permission("expenses.view") or current_user.has_permission("expenses")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view expenses.",
            "error": "Permission denied for 'expenses.view'",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    category_id = request.args.get("category_id", type=int)

    query = Expense.query.filter_by(business_id=current_user.business_id)

    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if category_id:
        query = query.filter_by(category_id=category_id)

    expenses = query.order_by(Expense.expense_date.desc(), Expense.created_at.desc()).all()
    return jsonify([e.to_dict() for e in expenses])

@expenses_bp.route("", methods=["POST"])
@token_required
def create_expense(current_user):
    if not (current_user.has_permission("expenses.create") or current_user.has_permission("expenses")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to record expenses.",
            "error": "Permission denied for 'expenses.create'",
            "error_code": "FORBIDDEN"
        }), 403

    data = request.get_json() or {}
    title = data.get("title")
    amount = float(data.get("amount", 0.0))

    if not title or amount <= 0:
        return jsonify({"error": "Expense title and positive amount are required"}), 400

    expense = Expense(
        business_id=current_user.business_id,
        branch_id=data.get("branch_id", current_user.branch_id),
        category_id=data.get("category_id"),
        title=title,
        amount=amount,
        vendor=data.get("vendor", ""),
        payment_method=data.get("payment_method", "CASH"),
        notes=data.get("notes", ""),
        created_by_user_id=current_user.id
    )
    db.session.add(expense)
    db.session.commit()

    return jsonify({
        "message": "Expense recorded successfully",
        "expense": expense.to_dict()
    }), 201

@expenses_bp.route("/categories", methods=["GET"])
@token_required
def list_categories(current_user):
    if not (current_user.has_permission("expenses.view") or current_user.has_permission("expenses")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view expense categories.",
            "error": "Permission denied for 'expenses.view'",
            "error_code": "FORBIDDEN"
        }), 403

    categories = ExpenseCategory.query.filter_by(business_id=current_user.business_id).all()
    return jsonify([c.to_dict() for c in categories])

@expenses_bp.route("/categories", methods=["POST"])
@token_required
def create_category(current_user):
    if not (current_user.has_permission("expenses.create") or current_user.has_permission("expenses")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to create expense categories.",
            "error": "Permission denied for 'expenses.create'",
            "error_code": "FORBIDDEN"
        }), 403
    data = request.get_json() or {}
    name = data.get("name")
    if not name:
        return jsonify({"error": "Category name is required"}), 400

    category = ExpenseCategory(
        business_id=current_user.business_id,
        name=name,
        description=data.get("description", "")
    )
    db.session.add(category)
    db.session.commit()
    return jsonify(category.to_dict()), 201
