from datetime import datetime, timedelta
from app.extensions import db
from app.models.purchase import Purchase, PurchaseItem
from app.models.product import Product
from app.models.party import Supplier
from app.models.business import Business, BusinessSettings
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.models.inventory import StockMovementType
from app.services.tax_service import TaxService
from app.services.stock_service import StockService
from app.services.ledger_service import LedgerService

class PurchaseService:
    @staticmethod
    def create_purchase(data, user_id=None):
        business_id = data["business_id"]
        branch_id = data["branch_id"]
        supplier_id = data["supplier_id"]
        raw_items = data.get("items", [])
        payments_data = data.get("payment", {})

        if not raw_items:
            raise ValueError("Purchase must contain at least one item")

        supplier = Supplier.query.get(supplier_id)
        if not supplier:
            raise ValueError(f"Supplier {supplier_id} not found")

        business = Business.query.get(business_id)
        settings = BusinessSettings.query.filter_by(business_id=business_id).first()
        if not settings:
            settings = BusinessSettings(business_id=business_id)
            db.session.add(settings)
            db.session.flush()

        is_interstate = False
        if supplier.state and business.state and supplier.state.strip().lower() != business.state.strip().lower():
            is_interstate = True

        calculated_items = []
        for itm in raw_items:
            product = Product.query.get(itm["product_id"])
            if not product:
                raise ValueError(f"Product {itm['product_id']} not found")

            qty = float(itm.get("quantity", 1.0))
            price = float(itm.get("unit_price", product.purchase_price))
            gst_rate = float(itm.get("gst_rate", product.gst_rate))

            calc = TaxService.calculate_item_tax(qty, price, 0.0, gst_rate, is_interstate)
            calc["product_id"] = product.id
            calc["product_name"] = product.name
            calc["hsn_sac"] = product.hsn_sac
            calc["unit"] = product.unit
            calculated_items.append(calc)

        additional_charges = float(data.get("additional_charges", 0.0))
        discount_amount = float(data.get("discount_amount", 0.0))

        totals = TaxService.calculate_invoice_totals(
            calculated_items,
            additional_charges=additional_charges,
            global_discount=discount_amount,
            is_interstate=is_interstate
        )

        grand_total = totals["grand_total"]
        paid_amount = float(payments_data.get("amount", 0.0))
        balance_amount = round(grand_total - paid_amount, 2)

        po_number = data.get("purchase_number")
        if not po_number:
            po_number = f"{settings.purchase_prefix}{settings.next_purchase_number}"
            settings.next_purchase_number += 1

        due_days = int(data.get("due_days", 30))
        purchase_date = datetime.strptime(data["purchase_date"], "%Y-%m-%d").date() if "purchase_date" in data else datetime.utcnow().date()
        due_date = purchase_date + timedelta(days=due_days)

        status = "PAID" if balance_amount <= 0.01 else ("PARTIAL" if paid_amount > 0 else "RECEIVED")

        purchase = Purchase(
            business_id=business_id,
            branch_id=branch_id,
            supplier_id=supplier_id,
            purchase_number=po_number,
            supplier_invoice_number=data.get("supplier_invoice_number", ""),
            purchase_date=purchase_date,
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
            created_by_user_id=user_id
        )
        db.session.add(purchase)
        db.session.flush()

        # Add purchase items & increment stock
        for c in calculated_items:
            item = PurchaseItem(
                purchase_id=purchase.id,
                product_id=c["product_id"],
                product_name=c["product_name"],
                hsn_sac=c["hsn_sac"],
                quantity=c["quantity"],
                unit=c["unit"],
                unit_price=c["unit_price"],
                gst_rate=c["gst_rate"],
                cgst_amount=c["cgst_amount"],
                sgst_amount=c["sgst_amount"],
                igst_amount=c["igst_amount"],
                total_amount=c["total_amount"]
            )
            db.session.add(item)

            # Stock increases
            StockService.adjust_stock(
                branch_id=branch_id,
                product_id=c["product_id"],
                quantity=c["quantity"],
                movement_type=StockMovementType.IN,
                reference_type="PURCHASE",
                reference_id=purchase.id,
                notes=f"Purchase from {supplier.name} ({po_number})",
                user_id=user_id
            )

        # Supplier Ledger Credit (Increases payable)
        LedgerService.record_supplier_entry(
            business_id=business_id,
            supplier_id=supplier_id,
            voucher_type="PURCHASE",
            voucher_number=po_number,
            debit_amount=0.0,
            credit_amount=grand_total,
            narration=f"Purchase of raw materials / goods ({po_number})",
            voucher_id=purchase.id,
            entry_date=purchase_date
        )

        # If payment made to supplier
        if paid_amount > 0:
            pay_method = payments_data.get("payment_method", PaymentMethod.BANK_TRANSFER)
            payment_record = Payment(
                business_id=business_id,
                branch_id=branch_id,
                reference_type="PURCHASE",
                reference_id=purchase.id,
                party_type="SUPPLIER",
                party_id=supplier_id,
                amount=paid_amount,
                payment_method=pay_method,
                transaction_ref=payments_data.get("transaction_ref", ""),
                payment_date=purchase_date,
                notes=payments_data.get("notes", f"Supplier payment for {po_number}"),
                status=PaymentStatus.SUCCESSFUL,
                created_by_user_id=user_id
            )
            db.session.add(payment_record)
            db.session.flush()

            # Supplier Ledger Debit (Decreases payable)
            LedgerService.record_supplier_entry(
                business_id=business_id,
                supplier_id=supplier_id,
                voucher_type="PAYMENT",
                voucher_number=f"PAY-{payment_record.id}",
                debit_amount=paid_amount,
                credit_amount=0.0,
                narration=f"Payment made to {supplier.name} via {pay_method}",
                voucher_id=payment_record.id,
                entry_date=purchase_date
            )

        db.session.commit()
        return purchase
