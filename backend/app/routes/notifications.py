from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.notification import Notification
from app.utils.auth import token_required

notifications_bp = Blueprint("notifications", __name__, url_prefix="/api/notifications")

@notifications_bp.route("", methods=["GET"])
@token_required
def list_notifications(current_user):
    branch_id = request.args.get("branch_id", type=int)
    query = Notification.query.filter_by(business_id=current_user.business_id)
    if branch_id:
        query = query.filter(db.or_(Notification.branch_id == branch_id, Notification.branch_id == None))

    notifications = query.order_by(Notification.created_at.desc()).limit(50).all()
    unread_count = Notification.query.filter_by(business_id=current_user.business_id, is_read=False).count()

    return jsonify({
        "notifications": [n.to_dict() for n in notifications],
        "unread_count": unread_count
    })

@notifications_bp.route("/<int:notif_id>/read", methods=["POST"])
@token_required
def mark_as_read(current_user, notif_id):
    notif = Notification.query.filter_by(id=notif_id, business_id=current_user.business_id).first()
    if notif:
        notif.is_read = True
        db.session.commit()
    return jsonify({"message": "Marked as read"})

@notifications_bp.route("/read-all", methods=["POST"])
@token_required
def mark_all_as_read(current_user):
    Notification.query.filter_by(business_id=current_user.business_id, is_read=False).update({"is_read": True})
    db.session.commit()
    return jsonify({"message": "All marked as read"})
