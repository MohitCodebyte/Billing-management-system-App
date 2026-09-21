import os

BASE_DIR = os.path.abspath(os.path.dirname(__file__))

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "bharat-ledger-secret-key-2026-industrial-suite")
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "bharat-ledger-jwt-secret-9716022075556801219")
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL", f"sqlite:///{os.path.join(BASE_DIR, '..', 'bharat_ledger.db')}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        "connect_args": {"timeout": 30, "check_same_thread": False}
    }
    INVOICE_PDF_DIR = os.path.join(BASE_DIR, "..", "generated_invoices")
    os.makedirs(INVOICE_PDF_DIR, exist_ok=True)

class TestConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
