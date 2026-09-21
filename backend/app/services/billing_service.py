from datetime import datetime, timedelta
from app.extensions import db
from app.models.invoice import Invoice, InvoiceItem, InvoiceStatus
from app.models.product import Product
from app.models.party import Customer
from app.models.business import Business, BusinessSettings
from app.models.payment import Payment, SplitPaymentDetail, PaymentMethod, PaymentStatus
from app.models.notification import Notification
from app.models.inventory import StockMovementType
from app.services.tax_service import TaxService
from app.services.stock_service import StockService
from app.services.ledger_service import LedgerService

class BillingService:
    @staticmethod
    def create_invoice(data, user_id=None):
        business_id = data["business_id"]
        branch_id = data["branch_id"]
        customer_id = data["customer_id"]
        raw_items = data.get("items", [])
        payments_data = data.get("payment", {})  # payment info (amount, method, splits, etc.)

        if not raw_items:
            raise ValueError("Invoice must contain at least one item")

        customer = Customer.query.get(customer_id)
        if not customer:
            raise ValueError(f"Customer {customer_id} not found")

        business = Business.query.get(business_id)
        settings = BusinessSettings.query.filter_by(business_id=business_id).first()
        if not settings:
            settings = BusinessSettings(business_id=business_id)
            db.session.add(settings)
            db.session.flush()

        # Check interstate supply
        is_interstate = False
        if customer.state and business.state and customer.state.strip().lower() != business.state.strip().lower():
            is_interstate = True

        calculated_items = []
        for itm in raw_items:
            product = Product.query.get(itm["product_id"])
            if not product:
                raise ValueError(f"Product {itm['product_id']} not found")

            qty = float(itm.get("quantity", 1.0))
            price = float(itm.get("unit_price", product.selling_price))
            discount = float(itm.get("discount_percent", 0.0))
            gst_rate = float(itm.get("gst_rate", product.gst_rate))

            calc = TaxService.calculate_item_tax(qty, price, discount, gst_rate, is_interstate)
            calc["product_id"] = product.id
            calc["product_name"] = product.name
            calc["hsn_sac"] = product.hsn_sac
            calc["unit"] = product.unit
            calculated_items.append(calc)

        additional_charges = float(data.get("additional_charges", 0.0))
        global_discount = float(data.get("global_discount", 0.0))

        totals = TaxService.calculate_invoice_totals(
            calculated_items,
            additional_charges=additional_charges,
            global_discount=global_discount,
            is_interstate=is_interstate
        )

        grand_total = totals["grand_total"]
        paid_amount = float(payments_data.get("amount", 0.0))

        if paid_amount > grand_total + 0.01:
            raise ValueError(f"Paid amount (₹{paid_amount}) cannot exceed grand total (₹{grand_total})")

        balance_amount = round(grand_total - paid_amount, 2)

        # Generate invoice number atomically
        inv_number = data.get("invoice_number")
        if not inv_number:
            inv_number = f"{settings.invoice_prefix}{settings.next_invoice_number}"
            settings.next_invoice_number += 1

        due_days = int(data.get("due_days", 15))
        invoice_date = datetime.strptime(data["invoice_date"], "%Y-%m-%d").date() if "invoice_date" in data else datetime.utcnow().date()
        due_date = invoice_date + timedelta(days=due_days)

        status = InvoiceStatus.PAID if balance_amount <= 0.01 else (InvoiceStatus.PARTIAL if paid_amount > 0 else InvoiceStatus.ISSUED)

        invoice = Invoice(
            business_id=business_id,
            branch_id=branch_id,
            customer_id=customer_id,
            invoice_number=inv_number,
            invoice_date=invoice_date,
            due_date=due_date,
            subtotal=totals["subtotal"],
            discount_amount=totals["discount_amount"],
            taxable_value=totals["taxable_value"],
            cgst_amount=totals["cgst_amount"],
            sgst_amount=totals["sgst_amount"],
            igst_amount=totals["igst_amount"],
            additional_charges=totals["additional_charges"],
            round_off=totals["round_off"],
            grand_total=grand_total,
            paid_amount=paid_amount,
            balance_amount=balance_amount,
            status=status,
            notes=data.get("notes", ""),
            payment_terms=data.get("payment_terms", f"Net {due_days}"),
            created_by_user_id=user_id
        )
        db.session.add(invoice)
        db.session.flush()

        # Add line items & update inventory
        for c in calculated_items:
            item = InvoiceItem(
                invoice_id=invoice.id,
                product_id=c["product_id"],
                product_name=c["product_name"],
                hsn_sac=c["hsn_sac"],
                quantity=c["quantity"],
                unit=c["unit"],
                unit_price=c["unit_price"],
                discount_amount=c["discount_amount"],
                taxable_amount=c["taxable_amount"],
                gst_rate=c["gst_rate"],
                cgst_amount=c["cgst_amount"],
                sgst_amount=c["sgst_amount"],
                igst_amount=c["igst_amount"],
                total_amount=c["total_amount"]
            )
            db.session.add(item)

            # Deduct stock
            StockService.adjust_stock(
                branch_id=branch_id,
                product_id=c["product_id"],
                quantity=c["quantity"],
                movement_type=StockMovementType.OUT,
                reference_type="INVOICE",
                reference_id=invoice.id,
                notes=f"Sale on Invoice {inv_number}",
                user_id=user_id
            )

        # Record Customer Ledger Debit for the total invoice value
        LedgerService.record_customer_entry(
            business_id=business_id,
            customer_id=customer_id,
            voucher_type="INVOICE",
            voucher_number=inv_number,
            debit_amount=grand_total,
            credit_amount=0.0,
            narration=f"Goods sold on Invoice {inv_number}",
            voucher_id=invoice.id,
            entry_date=invoice_date
        )

        # Record Payment if paid_amount > 0
        payment_record = None
        if paid_amount > 0:
            pay_method = payments_data.get("payment_method", PaymentMethod.CASH)
            splits_data = payments_data.get("splits", [])

            # If split payment, validate that the sum of splits equals paid_amount
            if pay_method == PaymentMethod.SPLIT and splits_data:
                split_sum = sum(float(s["amount"]) for s in splits_data)
                if abs(split_sum - paid_amount) > 0.05:
                    raise ValueError(f"Split sum (₹{split_sum}) does not match paid amount (₹{paid_amount})")

            payment_record = Payment(
                business_id=business_id,
                branch_id=branch_id,
                reference_type="INVOICE",
                reference_id=invoice.id,
                party_type="CUSTOMER",
                party_id=customer_id,
                amount=paid_amount,
                payment_method=pay_method,
                transaction_ref=payments_data.get("transaction_ref", ""),
                payment_date=invoice_date,
                notes=payments_data.get("notes", f"Payment for {inv_number}"),
                status=PaymentStatus.SUCCESSFUL,
                created_by_user_id=user_id
            )
            db.session.add(payment_record)
            db.session.flush()

            if pay_method == PaymentMethod.SPLIT and splits_data:
                for sp in splits_data:
                    split_item = SplitPaymentDetail(
                        payment_id=payment_record.id,
                        method=sp["method"],
                        amount=float(sp["amount"]),
                        reference=sp.get("reference", "")
                    )
                    db.session.add(split_item)

            # Record Customer Ledger Credit for payment received
            LedgerService.record_customer_entry(
                business_id=business_id,
                customer_id=customer_id,
                voucher_type="PAYMENT",
                voucher_number=f"RCPT-{payment_record.id}",
                debit_amount=0.0,
                credit_amount=paid_amount,
                narration=f"Payment received via {pay_method} for {inv_number}",
                voucher_id=payment_record.id,
                entry_date=invoice_date
            )

        # Add Notification
        notification = Notification(
            business_id=business_id,
            branch_id=branch_id,
            type="INVOICE_CREATED",
            title="New Invoice Created",
            message=f"Invoice {inv_number} created for {customer.name} (₹{grand_total})",
            reference_type="INVOICE",
            reference_id=invoice.id
        )
        db.session.add(notification)

        db.session.commit()
        return invoice
