from functools import wraps
from datetime import datetime, timedelta
import jwt
from flask import request, jsonify, current_app
from app.models.user import User

def generate_token(user):
    payload = {
        "user_id": user.id,
        "business_id": user.business_id,
        "branch_id": user.branch_id,
        "role": user.role,
        "email": user.email,
        "exp": datetime.utcnow() + timedelta(days=30)
    }
    return jwt.encode(payload, current_app.config["JWT_SECRET_KEY"], algorithm="HS256")

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return jsonify({"error": "Authentication token is missing"}), 401

        try:
            parts = auth_header.split()
            if len(parts) == 2 and parts[0].lower() == "bearer":
                token = parts[1]
            else:
                token = auth_header

            payload = jwt.decode(token, current_app.config["JWT_SECRET_KEY"], algorithms=["HS256"])
            current_user = User.query.get(payload["user_id"])
            if not current_user or not current_user.is_active:
                return jsonify({"error": "Invalid user account or deactivated"}), 401
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token has expired, please log in again"}), 401
        except Exception as e:
            return jsonify({"error": f"Invalid token: {str(e)}"}), 401

        return f(current_user, *args, **kwargs)
    return decorated

def permission_required(permission):
    def decorator(f):
        @wraps(f)
        def decorated_function(current_user, *args, **kwargs):
            if not current_user.has_permission(permission):
                return jsonify({
                    "success": False,
                    "message": "You do not have permission to perform this action.",
                    "error": f"Permission denied for '{permission}'",
                    "error_code": "FORBIDDEN"
                }), 403
            return f(current_user, *args, **kwargs)
        return decorated_function
    return decorator

