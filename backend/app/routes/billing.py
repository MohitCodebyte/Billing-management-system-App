from flask import Blueprint, request, jsonify, send_file
from app.extensions import db
from app.models.invoice import Invoice, InvoiceStatus
from app.models.product import Product
from app.models.party import Customer
from app.models.business import Business
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.services.billing_service import BillingService
from app.services.tax_service import TaxService
from app.services.ledger_service import LedgerService
from app.services.pdf_service import PdfService
from app.utils.auth import token_required

billing_bp = Blueprint("billing", __name__, url_prefix="/api")

@billing_bp.route("/billing/calculate", methods=["POST"])
@token_required
def calculate_cart(current_user):
    data = request.get_json() or {}
    customer_id = data.get("customer_id")
    raw_items = data.get("items", [])
    additional_charges = float(data.get("additional_charges", 0.0))
    global_discount = float(data.get("global_discount", 0.0))

    is_interstate = False
    if customer_id:
        cust = Customer.query.get(customer_id)
        biz = Business.query.get(current_user.business_id)
        if cust and biz and cust.state and biz.state and cust.state.strip().lower() != biz.state.strip().lower():
            is_interstate = True

    calculated_items = []
    for itm in raw_items:
        product = Product.query.get(itm.get("product_id"))
        qty = float(itm.get("quantity", 1.0))
        price = float(itm.get("unit_price", product.selling_price if product else 0.0))
        gst_rate = float(itm.get("gst_rate", product.gst_rate if product else 18.0))
        discount_percent = float(itm.get("discount_percent", 0.0))

        c = TaxService.calculate_item_tax(qty, price, discount_percent, gst_rate, is_interstate)
        c["product_id"] = product.id if product else None
        c["product_name"] = product.name if product else itm.get("product_name", "")
        c["unit"] = product.unit if product else "PCS"
        calculated_items.append(c)

    totals = TaxService.calculate_invoice_totals(
        calculated_items,
        additional_charges=additional_charges,
        global_discount=global_discount,
        is_interstate=is_interstate
    )

    return jsonify({
        "items": calculated_items,
        "totals": totals,
        "is_interstate": is_interstate
    })

@billing_bp.route("/invoices", methods=["POST"])
@token_required
def create_invoice(current_user):
    data = request.get_json() or {}
    data["business_id"] = current_user.business_id
    if "branch_id" not in data or not data["branch_id"]:
        data["branch_id"] = current_user.branch_id

    try:
        invoice = BillingService.create_invoice(data, user_id=current_user.id)
        return jsonify({
            "message": "Invoice created successfully",
            "invoice": invoice.to_dict()
        }), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to create invoice: {str(e)}"}), 500

@billing_bp.route("/invoices", methods=["GET"])
@token_required
def list_invoices(current_user):
    branch_id = request.args.get("branch_id", type=int)
    customer_id = request.args.get("customer_id", type=int)
    status = request.args.get("status")
    search = request.args.get("search")

    query = Invoice.query.filter_by(business_id=current_user.business_id)

    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    if customer_id:
        query = query.filter_by(customer_id=customer_id)
    if status:
        query = query.filter_by(status=status.upper())
    if search:
        query = query.filter(Invoice.invoice_number.ilike(f"%{search}%"))

    invoices = query.order_by(Invoice.created_at.desc()).all()
    return jsonify([inv.to_dict() for inv in invoices])

@billing_bp.route("/invoices/<int:invoice_id>", methods=["GET"])
@token_required
def get_invoice(current_user, invoice_id):
    invoice = Invoice.query.filter_by(id=invoice_id, business_id=current_user.business_id).first()
    if not invoice:
        return jsonify({"error": "Invoice not found"}), 404
    return jsonify(invoice.to_dict())

@billing_bp.route("/invoices/<int:invoice_id>/pdf", methods=["GET"])
@token_required
def download_invoice_pdf(current_user, invoice_id):
    invoice = Invoice.query.filter_by(id=invoice_id, business_id=current_user.business_id).first()
    if not invoice:
        return jsonify({"error": "Invoice not found"}), 404

    try:
        filepath = PdfService.generate_invoice_pdf(invoice)
        return send_file(filepath, as_attachment=True, download_name=f"{invoice.invoice_number}.pdf")
    except Exception as e:
        return jsonify({"error": f"Failed to generate PDF: {str(e)}"}), 500

@billing_bp.route("/invoices/<int:invoice_id>/payments", methods=["POST"])
@token_required
def record_invoice_payment(current_user, invoice_id):
    invoice = Invoice.query.filter_by(id=invoice_id, business_id=current_user.business_id).first()
    if not invoice:
        return jsonify({"error": "Invoice not found"}), 404

    data = request.get_json() or {}
    amount = float(data.get("amount", 0.0))
    if amount <= 0:
        return jsonify({"error": "Amount must be greater than 0"}), 400

    if amount > invoice.balance_amount + 0.01:
        return jsonify({"error": f"Amount (₹{amount}) cannot exceed remaining balance (₹{invoice.balance_amount})"}), 400

    pay_method = data.get("payment_method", PaymentMethod.CASH)

    payment = Payment(
        business_id=current_user.business_id,
        branch_id=invoice.branch_id,
        reference_type="INVOICE",
        reference_id=invoice.id,
        party_type="CUSTOMER",
        party_id=invoice.customer_id,
        amount=amount,
        payment_method=pay_method,
        transaction_ref=data.get("transaction_ref", ""),
        notes=data.get("notes", f"Payment for {invoice.invoice_number}"),
        status=PaymentStatus.SUCCESSFUL,
        created_by_user_id=current_user.id
    )
    db.session.add(payment)

    invoice.paid_amount = round(invoice.paid_amount + amount, 2)
    invoice.balance_amount = round(max(0.0, invoice.grand_total - invoice.paid_amount), 2)
    if invoice.balance_amount <= 0.01:
        invoice.status = InvoiceStatus.PAID
    else:
        invoice.status = InvoiceStatus.PARTIAL

    # Update Customer Ledger
    LedgerService.record_customer_entry(
        business_id=current_user.business_id,
        customer_id=invoice.customer_id,
        voucher_type="PAYMENT",
        voucher_number=f"RCPT-{payment.id}",
        debit_amount=0.0,
        credit_amount=amount,
        narration=f"Payment received via {pay_method} for {invoice.invoice_number}",
        voucher_id=payment.id
    )

    db.session.commit()

    return jsonify({
        "message": "Payment recorded successfully",
        "invoice": invoice.to_dict()
    })
