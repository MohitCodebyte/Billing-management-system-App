from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.inventory import BranchStock, StockMovement, StockMovementType
from app.models.product import Product
from app.services.stock_service import StockService
from app.utils.auth import token_required

inventory_bp = Blueprint("inventory", __name__, url_prefix="/api/inventory")

@inventory_bp.route("/stock", methods=["GET"])
@token_required
def get_inventory_stock(current_user):
    branch_id = request.args.get("branch_id", current_user.branch_id, type=int)
    search = request.args.get("search")

    query = db.session.query(BranchStock, Product).join(Product, BranchStock.product_id == Product.id)\
        .filter(Product.business_id == current_user.business_id, Product.is_active == True)

    if branch_id:
        query = query.filter(BranchStock.branch_id == branch_id)
    if search:
        query = query.filter(
            db.or_(
                Product.name.ilike(f"%{search}%"),
                Product.sku.ilike(f"%{search}%")
            )
        )

    items = query.all()
    results = []
    for stock, prod in items:
        results.append({
            "stock_id": stock.id,
            "branch_id": stock.branch_id,
            "product_id": prod.id,
            "name": prod.name,
            "sku": prod.sku,
            "barcode": prod.barcode,
            "unit": prod.unit,
            "quantity": stock.quantity,
            "reserved_quantity": stock.reserved_quantity,
            "available_quantity": max(0.0, stock.quantity - stock.reserved_quantity),
            "min_stock": prod.min_stock,
            "is_low_stock": stock.quantity <= prod.min_stock,
            "purchase_price": prod.purchase_price,
            "selling_price": prod.selling_price,
            "valuation": round(stock.quantity * prod.purchase_price, 2),
            "updated_at": stock.updated_at.isoformat() if stock.updated_at else None
        })

    return jsonify(results)

@inventory_bp.route("/adjust", methods=["POST"])
@token_required
def adjust_stock(current_user):
    if not (current_user.has_permission("inventory.adjust") or current_user.has_permission("stock.manage")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to adjust stock.",
            "error": "Permission denied for 'inventory.adjust'",
            "error_code": "FORBIDDEN"
        }), 403

    data = request.get_json() or {}
    product_id = data.get("product_id")
    quantity = float(data.get("quantity", 0.0))
    movement_type = data.get("movement_type", StockMovementType.ADJUSTMENT).upper()
    branch_id = data.get("branch_id", current_user.branch_id)
    notes = data.get("notes", "Manual stock adjustment")

    if not product_id or quantity <= 0:
        return jsonify({"error": "Product ID and positive quantity are required"}), 400

    try:
        stock, movement = StockService.adjust_stock(
            branch_id=branch_id,
            product_id=product_id,
            quantity=quantity,
            movement_type=movement_type,
            reference_type="MANUAL_ADJUSTMENT",
            notes=notes,
            user_id=current_user.id
        )
        db.session.commit()
        return jsonify({
            "message": "Stock adjusted successfully",
            "stock": stock.to_dict(),
            "movement": movement.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to adjust stock: {str(e)}"}), 500

@inventory_bp.route("/history", methods=["GET"])
@token_required
def stock_history(current_user):
    if not (current_user.has_permission("stock.history") or current_user.has_permission("inventory.adjust") or current_user.has_permission("inventory")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view stock history.",
            "error": "Permission denied for 'stock.history'",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    product_id = request.args.get("product_id", type=int)
    movement_type = request.args.get("movement_type")

    query = db.session.query(StockMovement, Product).join(Product, StockMovement.product_id == Product.id)\
        .filter(Product.business_id == current_user.business_id)

    if branch_id:
        query = query.filter(StockMovement.branch_id == branch_id)
    if product_id:
        query = query.filter(StockMovement.product_id == product_id)
    if movement_type:
        query = query.filter(StockMovement.movement_type == movement_type.upper())

    movements = query.order_by(StockMovement.created_at.desc()).limit(100).all()
    results = []
    for m, p in movements:
        m_dict = m.to_dict()
        m_dict["product_name"] = p.name
        m_dict["sku"] = p.sku
        m_dict["unit"] = p.unit
        results.append(m_dict)

    return jsonify(results)
