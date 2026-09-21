from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.business import Business, BusinessSettings, PrinterSettings
from app.models.user import Role
from app.utils.auth import token_required

settings_bp = Blueprint("settings", __name__, url_prefix="/api/settings")

@settings_bp.route("/business", methods=["GET"])
@token_required
def get_business_settings(current_user):
    if not (current_user.has_permission("settings.view") or current_user.has_permission("settings") or Role.normalize(current_user.role) == Role.ADMIN):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view business settings.",
            "error": "Permission denied for 'settings.view'",
            "error_code": "FORBIDDEN"
        }), 403

    business = Business.query.get(current_user.business_id)
    settings = BusinessSettings.query.filter_by(business_id=current_user.business_id).first()
    if not settings:
        settings = BusinessSettings(business_id=current_user.business_id)
        db.session.add(settings)
        db.session.commit()

    return jsonify({
        "business": business.to_dict() if business else None,
        "settings": settings.to_dict(),
        "attribution": "© NexvoraTech LLP — Developed by Mohit"
    })

@settings_bp.route("/business", methods=["PUT"])
@token_required
def update_business_settings(current_user):
    if not (current_user.has_permission("settings.manage") or Role.normalize(current_user.role) in [Role.ADMIN, Role.OWNER]):
        return jsonify({
            "success": False,
            "message": "You do not have permission to update business settings.",
            "error": "Only Admin can update business settings",
            "error_code": "FORBIDDEN"
        }), 403

    business = Business.query.get(current_user.business_id)
    settings = BusinessSettings.query.filter_by(business_id=current_user.business_id).first()
    data = request.get_json() or {}

    biz_data = data.get("business", {})
    if biz_data and business:
        business.name = biz_data.get("name", business.name)
        business.trade_name = biz_data.get("trade_name", business.trade_name)
        business.gstin = biz_data.get("gstin", business.gstin)
        business.phone = biz_data.get("phone", business.phone)
        business.email = biz_data.get("email", business.email)
        business.address = biz_data.get("address", business.address)
        business.city = biz_data.get("city", business.city)
        business.state = biz_data.get("state", business.state)
        business.pincode = biz_data.get("pincode", business.pincode)

    set_data = data.get("settings", {})
    if set_data and settings:
        settings.invoice_prefix = set_data.get("invoice_prefix", settings.invoice_prefix)
        settings.purchase_prefix = set_data.get("purchase_prefix", settings.purchase_prefix)
        if "default_tax_rate" in set_data:
            settings.default_tax_rate = float(set_data["default_tax_rate"])
        settings.terms_and_conditions = set_data.get("terms_and_conditions", settings.terms_and_conditions)
        settings.enable_e_invoicing = set_data.get("enable_e_invoicing", settings.enable_e_invoicing)
        settings.enable_e_way_bill = set_data.get("enable_e_way_bill", settings.enable_e_way_bill)

    db.session.commit()
    return jsonify({
        "message": "Settings updated successfully",
        "business": business.to_dict() if business else None,
        "settings": settings.to_dict() if settings else None
    })

@settings_bp.route("/printer", methods=["GET"])
@token_required
def get_printer_settings(current_user):
    printer = PrinterSettings.query.filter_by(business_id=current_user.business_id).first()
    if not printer:
        printer = PrinterSettings(business_id=current_user.business_id, branch_id=current_user.branch_id)
        db.session.add(printer)
        db.session.commit()

    return jsonify(printer.to_dict())

@settings_bp.route("/printer", methods=["PUT"])
@token_required
def update_printer_settings(current_user):
    printer = PrinterSettings.query.filter_by(business_id=current_user.business_id).first()
    if not printer:
        printer = PrinterSettings(business_id=current_user.business_id, branch_id=current_user.branch_id)
        db.session.add(printer)

    data = request.get_json() or {}
    printer.printer_type = data.get("printer_type", printer.printer_type)
    printer.printer_name = data.get("printer_name", printer.printer_name)
    printer.ip_address = data.get("ip_address", printer.ip_address)
    if "port" in data:
        printer.port = int(data["port"])
    printer.paper_size = data.get("paper_size", printer.paper_size)
    if "auto_print" in data:
        printer.auto_print = bool(data["auto_print"])
    printer.header_text = data.get("header_text", printer.header_text)
    printer.footer_text = data.get("footer_text", printer.footer_text)

    db.session.commit()
    return jsonify({
        "message": "Printer settings updated successfully",
        "printer": printer.to_dict()
    })
