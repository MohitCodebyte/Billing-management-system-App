from datetime import datetime
from flask import Blueprint, request, jsonify
from app.services.report_service import ReportService
from app.utils.auth import token_required

reports_bp = Blueprint("reports", __name__, url_prefix="/api/reports")

@reports_bp.route("/sales", methods=["GET"])
@token_required
def sales_report(current_user):
    if not (current_user.has_permission("reports.sales") or current_user.has_permission("reports.view") or current_user.has_permission("reports")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view sales reports.",
            "error": "Permission denied for 'reports.sales'",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    start_date_str = request.args.get("start_date")
    end_date_str = request.args.get("end_date")

    start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else None
    end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else None

    report = ReportService.get_sales_analytics(
        business_id=current_user.business_id,
        branch_id=branch_id,
        start_date=start_date,
        end_date=end_date
    )
    return jsonify(report)

@reports_bp.route("/profit-loss", methods=["GET"])
@token_required
def profit_loss_report(current_user):
    if not (current_user.has_permission("reports.profit_loss") or current_user.has_permission("reports")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view profit & loss reports.",
            "error": "Permission denied for 'reports.profit_loss'",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    start_date_str = request.args.get("start_date")
    end_date_str = request.args.get("end_date")

    start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else None
    end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else None

    report = ReportService.get_profit_and_loss(
        business_id=current_user.business_id,
        branch_id=branch_id,
        start_date=start_date,
        end_date=end_date
    )
    return jsonify(report)

@reports_bp.route("/gst", methods=["GET"])
@token_required
def gst_report(current_user):
    if not (current_user.has_permission("reports.gst") or current_user.has_permission("reports")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view GST reports.",
            "error": "Permission denied for 'reports.gst'",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    start_date_str = request.args.get("start_date")
    end_date_str = request.args.get("end_date")

    start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else None
    end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else None

    report = ReportService.get_gst_report(
        business_id=current_user.business_id,
        branch_id=branch_id,
        start_date=start_date,
        end_date=end_date
    )
    return jsonify(report)

@reports_bp.route("/inventory", methods=["GET"])
@token_required
def inventory_report(current_user):
    if not (current_user.has_permission("reports.inventory") or current_user.has_permission("reports")):
        return jsonify({
            "success": False,
            "message": "You do not have permission to view inventory reports.",
            "error": "Permission denied for 'reports.inventory'",
            "error_code": "FORBIDDEN"
        }), 403

    branch_id = request.args.get("branch_id", type=int)
    report = ReportService.get_inventory_report(
        business_id=current_user.business_id,
        branch_id=branch_id
    )
    return jsonify(report)

