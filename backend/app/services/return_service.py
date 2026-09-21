from datetime import datetime
from app.extensions import db
from app.models.return_order import SalesReturn, PurchaseReturn, ReturnItem
from app.models.credit_debit import CreditNote, DebitNote
from app.models.invoice import Invoice
from app.models.purchase import Purchase
from app.models.inventory import StockMovementType
from app.services.stock_service import StockService
from app.services.ledger_service import LedgerService

class ReturnService:
    @staticmethod
    def process_sales_return(data, user_id=None):
        business_id = data["business_id"]
        branch_id = data["branch_id"]
        invoice_id = data["invoice_id"]
        items_data = data.get("items", [])

        invoice = Invoice.query.get(invoice_id)
        if not invoice:
            raise ValueError(f"Invoice {invoice_id} not found")

        if not items_data:
            raise ValueError("Return must contain at least one item")

        ret_number = f"SR-{int(datetime.utcnow().timestamp())}"
        total_refund = sum(float(it["quantity"]) * float(it["unit_price"]) for it in items_data)
        refund_type = data.get("refund_type", "CREDIT_NOTE")

        sales_return = SalesReturn(
            business_id=business_id,
            branch_id=branch_id,
            invoice_id=invoice_id,
            customer_id=invoice.customer_id,
            return_number=ret_number,
            return_date=datetime.utcnow().date(),
            refund_type=refund_type,
            total_amount=round(total_refund, 2),
            reason=data.get("reason", "Customer return"),
            notes=data.get("notes", "")
        )
        db.session.add(sales_return)
        db.session.flush()

        for it in items_data:
            item_total = float(it["quantity"]) * float(it["unit_price"])
            ret_item = ReturnItem(
                return_type="SALES",
                return_id=sales_return.id,
                product_id=it["product_id"],
                product_name=it.get("product_name", "Returned Product"),
                quantity=float(it["quantity"]),
                unit_price=float(it["unit_price"]),
                gst_rate=float(it.get("gst_rate", 18.0)),
                total_amount=round(item_total, 2),
                restock_inventory=it.get("restock_inventory", True)
            )
            db.session.add(ret_item)

            if ret_item.restock_inventory:
                StockService.adjust_stock(
                    branch_id=branch_id,
                    product_id=it["product_id"],
                    quantity=float(it["quantity"]),
                    movement_type=StockMovementType.RETURN,
                    reference_type="SALES_RETURN",
                    reference_id=sales_return.id,
                    notes=f"Restock from Sales Return {ret_number}",
                    user_id=user_id
                )

        # Generate Credit Note if refund_type == CREDIT_NOTE
        if refund_type == "CREDIT_NOTE":
            cn_number = f"CN-{int(datetime.utcnow().timestamp())}"
            cn = CreditNote(
                business_id=business_id,
                branch_id=branch_id,
                customer_id=invoice.customer_id,
                invoice_id=invoice.id,
                note_number=cn_number,
                note_date=datetime.utcnow().date(),
                amount=round(total_refund, 2),
                taxable_amount=round(total_refund / 1.18, 2),
                tax_amount=round(total_refund - (total_refund / 1.18), 2),
                reason=f"Credit note for sales return {ret_number}",
                status="ACTIVE"
            )
            db.session.add(cn)

            # Customer ledger credit (decreases customer debt)
            LedgerService.record_customer_entry(
                business_id=business_id,
                customer_id=invoice.customer_id,
                voucher_type="CREDIT_NOTE",
                voucher_number=cn_number,
                debit_amount=0.0,
                credit_amount=round(total_refund, 2),
                narration=f"Sales return against {invoice.invoice_number}",
                voucher_id=cn.id
            )

        db.session.commit()
        return sales_return

    @staticmethod
    def process_purchase_return(data, user_id=None):
        business_id = data["business_id"]
        branch_id = data["branch_id"]
        purchase_id = data["purchase_id"]
        items_data = data.get("items", [])

        purchase = Purchase.query.get(purchase_id)
        if not purchase:
            raise ValueError(f"Purchase {purchase_id} not found")

        if not items_data:
            raise ValueError("Return must contain at least one item")

        ret_number = f"PR-{int(datetime.utcnow().timestamp())}"
        total_refund = sum(float(it["quantity"]) * float(it["unit_price"]) for it in items_data)
        refund_type = data.get("refund_type", "DEBIT_NOTE")

        purchase_return = PurchaseReturn(
            business_id=business_id,
            branch_id=branch_id,
            purchase_id=purchase_id,
            supplier_id=purchase.supplier_id,
            return_number=ret_number,
            return_date=datetime.utcnow().date(),
            refund_type=refund_type,
            total_amount=round(total_refund, 2),
            reason=data.get("reason", "Defective goods / Rejected"),
            notes=data.get("notes", "")
        )
        db.session.add(purchase_return)
        db.session.flush()

        for it in items_data:
            item_total = float(it["quantity"]) * float(it["unit_price"])
            ret_item = ReturnItem(
                return_type="PURCHASE",
                return_id=purchase_return.id,
                product_id=it["product_id"],
                product_name=it.get("product_name", "Returned Product"),
                quantity=float(it["quantity"]),
                unit_price=float(it["unit_price"]),
                gst_rate=float(it.get("gst_rate", 18.0)),
                total_amount=round(item_total, 2),
                restock_inventory=it.get("restock_inventory", True)
            )
            db.session.add(ret_item)

            if ret_item.restock_inventory:
                StockService.adjust_stock(
                    branch_id=branch_id,
                    product_id=it["product_id"],
                    quantity=float(it["quantity"]),
                    movement_type=StockMovementType.OUT,
                    reference_type="PURCHASE_RETURN",
                    reference_id=purchase_return.id,
                    notes=f"Stock deduction from Purchase Return {ret_number}",
                    user_id=user_id
                )

        if refund_type == "DEBIT_NOTE":
            dn_number = f"DN-{int(datetime.utcnow().timestamp())}"
            dn = DebitNote(
                business_id=business_id,
                branch_id=branch_id,
                supplier_id=purchase.supplier_id,
                purchase_id=purchase.id,
                note_number=dn_number,
                note_date=datetime.utcnow().date(),
                amount=round(total_refund, 2),
                taxable_amount=round(total_refund / 1.18, 2),
                tax_amount=round(total_refund - (total_refund / 1.18), 2),
                reason=f"Debit note for purchase return {ret_number}",
                status="ACTIVE"
            )
            db.session.add(dn)

            # Supplier ledger debit (decreases supplier payable)
            LedgerService.record_supplier_entry(
                business_id=business_id,
                supplier_id=purchase.supplier_id,
                voucher_type="DEBIT_NOTE",
                voucher_number=dn_number,
                debit_amount=round(total_refund, 2),
                credit_amount=0.0,
                narration=f"Purchase return against {purchase.purchase_number}",
                voucher_id=dn.id
            )

        db.session.commit()
        return purchase_return
