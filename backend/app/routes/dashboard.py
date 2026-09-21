from datetime import datetime
from flask import Blueprint, jsonify, request
from sqlalchemy import func
from app.models.invoice import Invoice
from app.models.party import Customer, Supplier
from app.models.product import Product
from app.models.inventory import BranchStock
from app.models.business import Branch
from app.utils.auth import token_required

dashboard_bp = Blueprint("dashboard", __name__, url_prefix="/api/dashboard")

@dashboard_bp.route("", methods=["GET"])
@token_required
def get_dashboard(current_user):
    business_id = current_user.business_id
    branch_id = request.args.get("branch_id", current_user.branch_id, type=int)

    today = datetime.utcnow().date()

    # 1. Today's sales
    today_invoices = Invoice.query.filter_by(business_id=business_id, invoice_date=today)
    if branch_id:
        today_invoices = today_invoices.filter_by(branch_id=branch_id)
    today_invoices_list = today_invoices.all()
    today_sales = sum(i.grand_total for i in today_invoices_list)
    today_invoice_count = len(today_invoices_list)

    # 2. Total Receivables
    customers = Customer.query.filter_by(business_id=business_id, is_active=True).all()
    total_receivables = sum(c.current_balance for c in customers if c.current_balance > 0)

    # 3. Total Payables
    suppliers = Supplier.query.filter_by(business_id=business_id, is_active=True).all()
    total_payables = sum(s.current_payable for s in suppliers if s.current_payable > 0)

    # 4. Inventory Valuation & Low Stock
    products = Product.query.filter_by(business_id=business_id, is_active=True).all()
    total_valuation = 0.0
    low_stock_products = []

    for p in products:
        stock_qty = p.get_stock(branch_id)
        total_valuation += stock_qty * p.purchase_price
        if stock_qty <= p.min_stock:
            low_stock_products.append({
                "id": p.id,
                "name": p.name,
                "sku": p.sku,
                "current_stock": stock_qty,
                "min_stock": p.min_stock,
                "unit": p.unit
            })

    # 5. Recent Invoices
    recent_query = Invoice.query.filter_by(business_id=business_id)
    if branch_id:
        recent_query = recent_query.filter_by(branch_id=branch_id)
    recent_invoices = recent_query.order_by(Invoice.created_at.desc()).limit(5).all()

    active_branch = Branch.query.get(branch_id) if branch_id else None

    return jsonify({
        "stats": {
            "today_sales": round(today_sales, 2),
            "today_invoices": today_invoice_count,
            "total_receivables": round(total_receivables, 2),
            "total_payables": round(total_payables, 2),
            "total_inventory_valuation": round(total_valuation, 2),
            "low_stock_count": len(low_stock_products),
            "total_customers": len(customers),
            "total_products": len(products)
        },
        "recent_invoices": [inv.to_dict() for inv in recent_invoices],
        "low_stock_items": low_stock_products[:5],
        "active_branch": active_branch.to_dict() if active_branch else None,
        "attribution": "© NexvoraTech LLP — Developed by Mohit"
    }), 200
