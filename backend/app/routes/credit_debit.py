from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.credit_debit import CreditNote, DebitNote
from app.utils.auth import token_required

credit_debit_bp = Blueprint("credit_debit", __name__, url_prefix="/api/notes")

@credit_debit_bp.route("/credit", methods=["GET"])
@token_required
def list_credit_notes(current_user):
    branch_id = request.args.get("branch_id", type=int)
    customer_id = request.args.get("customer_id", type=int)

    query = CreditNote.query.filter_by(business_id=current_user.business_id)
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if customer_id:
        query = query.filter_by(customer_id=customer_id)

    notes = query.order_by(CreditNote.created_at.desc()).all()
    return jsonify([n.to_dict() for n in notes])

@credit_debit_bp.route("/debit", methods=["GET"])
@token_required
def list_debit_notes(current_user):
    branch_id = request.args.get("branch_id", type=int)
    supplier_id = request.args.get("supplier_id", type=int)

    query = DebitNote.query.filter_by(business_id=current_user.business_id)
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if supplier_id:
        query = query.filter_by(supplier_id=supplier_id)

    notes = query.order_by(DebitNote.created_at.desc()).all()
    return jsonify([n.to_dict() for n in notes])
