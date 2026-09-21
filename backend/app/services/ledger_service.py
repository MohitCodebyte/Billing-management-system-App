from datetime import datetime
from app.extensions import db
from app.models.ledger import CustomerLedgerEntry, SupplierLedgerEntry
from app.models.party import Customer, Supplier

class LedgerService:
    @staticmethod
    def record_customer_entry(business_id, customer_id, voucher_type, voucher_number,
                              debit_amount=0.0, credit_amount=0.0, narration="", voucher_id=None, entry_date=None):
        customer = Customer.query.get(customer_id)
        if not customer:
            raise ValueError(f"Customer with ID {customer_id} not found")

        # Current balance: positive means customer owes us (Debit)
        new_balance = customer.current_balance + debit_amount - credit_amount
        customer.current_balance = round(new_balance, 2)

        entry = CustomerLedgerEntry(
            business_id=business_id,
            customer_id=customer_id,
            entry_date=entry_date or datetime.utcnow().date(),
            voucher_type=voucher_type,
            voucher_number=voucher_number,
            voucher_id=voucher_id,
            debit_amount=round(debit_amount, 2),
            credit_amount=round(credit_amount, 2),
            running_balance=round(new_balance, 2),
            narration=narration
        )
        db.session.add(entry)
        return entry

    @staticmethod
    def record_supplier_entry(business_id, supplier_id, voucher_type, voucher_number,
                              debit_amount=0.0, credit_amount=0.0, narration="", voucher_id=None, entry_date=None):
        supplier = Supplier.query.get(supplier_id)
        if not supplier:
            raise ValueError(f"Supplier with ID {supplier_id} not found")

        # Current payable: positive means we owe supplier (Credit)
        new_payable = supplier.current_payable + credit_amount - debit_amount
        supplier.current_payable = round(new_payable, 2)

        entry = SupplierLedgerEntry(
            business_id=business_id,
            supplier_id=supplier_id,
            entry_date=entry_date or datetime.utcnow().date(),
            voucher_type=voucher_type,
            voucher_number=voucher_number,
            voucher_id=voucher_id,
            debit_amount=round(debit_amount, 2),
            credit_amount=round(credit_amount, 2),
            running_balance=round(new_payable, 2),
            narration=narration
        )
        db.session.add(entry)
        return entry
