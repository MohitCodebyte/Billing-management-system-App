from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.product import Product, Category
from app.models.inventory import BranchStock
from app.utils.auth import token_required

products_bp = Blueprint("products", __name__, url_prefix="/api/products")

@products_bp.route("", methods=["GET"])
@token_required
def list_products(current_user):
    branch_id = request.args.get("branch_id", current_user.branch_id, type=int)
    search = request.args.get("search")
    category_id = request.args.get("category_id", type=int)
    is_low_stock = request.args.get("low_stock", type=bool)

    query = Product.query.filter_by(business_id=current_user.business_id, is_active=True)

    if category_id:
        query = query.filter_by(category_id=category_id)
    if search:
        query = query.filter(
            db.or_(
                Product.name.ilike(f"%{search}%"),
                Product.sku.ilike(f"%{search}%"),
                Product.barcode.ilike(f"%{search}%"),
                Product.hsn_sac.ilike(f"%{search}%")
            )
        )

    products = query.order_by(Product.name.asc()).all()
    results = [p.to_dict(branch_id=branch_id) for p in products]

    if is_low_stock:
        results = [p for p in results if p["is_low_stock"]]

    return jsonify(results)

@products_bp.route("/<int:product_id>", methods=["GET"])
@token_required
def get_product(current_user, product_id):
    branch_id = request.args.get("branch_id", current_user.branch_id, type=int)
    product = Product.query.filter_by(id=product_id, business_id=current_user.business_id).first()
    if not product:
        return jsonify({"error": "Product not found"}), 404
    return jsonify(product.to_dict(branch_id=branch_id))

@products_bp.route("", methods=["POST"])
@token_required
def create_product(current_user):
    data = request.get_json() or {}
    name = data.get("name")
    sku = data.get("sku")
    selling_price = data.get("selling_price")

    if not name or not sku or selling_price is None:
        return jsonify({"error": "Product name, SKU, and selling price are required"}), 400

    existing = Product.query.filter_by(business_id=current_user.business_id, sku=sku).first()
    if existing:
        return jsonify({"error": f"Product with SKU '{sku}' already exists"}), 400

    product = Product(
        business_id=current_user.business_id,
        category_id=data.get("category_id"),
        name=name,
        sku=sku,
        barcode=data.get("barcode", ""),
        hsn_sac=data.get("hsn_sac", "8481"),
        unit=data.get("unit", "PCS"),
        purchase_price=float(data.get("purchase_price", 0.0)),
        selling_price=float(selling_price),
        mrp=float(data.get("mrp", selling_price)),
        gst_rate=float(data.get("gst_rate", 18.0)),
        min_stock=float(data.get("min_stock", 10.0)),
        max_stock=float(data.get("max_stock", 1000.0)),
        brand=data.get("brand", "Standard"),
        description=data.get("description", ""),
        image_url=data.get("image_url", "")
    )
    db.session.add(product)
    db.session.flush()

    # Initial stock if provided
    initial_stock = float(data.get("initial_stock", 0.0))
    branch_id = data.get("branch_id", current_user.branch_id)
    if branch_id:
        stock = BranchStock(
            branch_id=branch_id,
            product_id=product.id,
            quantity=initial_stock
        )
        db.session.add(stock)

    db.session.commit()
    return jsonify({
        "message": "Product created successfully",
        "product": product.to_dict(branch_id=branch_id)
    }), 201

@products_bp.route("/<int:product_id>", methods=["PUT"])
@token_required
def update_product(current_user, product_id):
    product = Product.query.filter_by(id=product_id, business_id=current_user.business_id).first()
    if not product:
        return jsonify({"error": "Product not found"}), 404

    data = request.get_json() or {}
    product.name = data.get("name", product.name)
    product.category_id = data.get("category_id", product.category_id)
    product.barcode = data.get("barcode", product.barcode)
    product.hsn_sac = data.get("hsn_sac", product.hsn_sac)
    product.unit = data.get("unit", product.unit)
    if "purchase_price" in data:
        product.purchase_price = float(data["purchase_price"])
    if "selling_price" in data:
        product.selling_price = float(data["selling_price"])
    if "mrp" in data:
        product.mrp = float(data["mrp"])
    if "gst_rate" in data:
        product.gst_rate = float(data["gst_rate"])
    if "min_stock" in data:
        product.min_stock = float(data["min_stock"])
    if "max_stock" in data:
        product.max_stock = float(data["max_stock"])
    product.brand = data.get("brand", product.brand)
    product.description = data.get("description", product.description)

    db.session.commit()
    return jsonify({
        "message": "Product updated successfully",
        "product": product.to_dict(branch_id=current_user.branch_id)
    })

@products_bp.route("/<int:product_id>", methods=["DELETE"])
@token_required
def delete_product(current_user, product_id):
    product = Product.query.filter_by(id=product_id, business_id=current_user.business_id).first()
    if not product:
        return jsonify({"error": "Product not found"}), 404

    product.is_active = False
    db.session.commit()
    return jsonify({"message": "Product deactivated successfully"})

@products_bp.route("/categories", methods=["GET"])
@token_required
def list_categories(current_user):
    categories = Category.query.filter_by(business_id=current_user.business_id).all()
    return jsonify([c.to_dict() for c in categories])

@products_bp.route("/categories", methods=["POST"])
@token_required
def create_category(current_user):
    data = request.get_json() or {}
    name = data.get("name")
    if not name:
        return jsonify({"error": "Category name is required"}), 400

    category = Category(
        business_id=current_user.business_id,
        name=name,
        description=data.get("description", "")
    )
    db.session.add(category)
    db.session.commit()
    return jsonify(category.to_dict()), 201
