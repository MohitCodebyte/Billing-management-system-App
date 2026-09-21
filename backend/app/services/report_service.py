from datetime import datetime, timedelta
from sqlalchemy import func
from app.extensions import db
from app.models.invoice import Invoice, InvoiceItem
from app.models.purchase import Purchase, PurchaseItem
from app.models.expense import Expense
from app.models.inventory import BranchStock
from app.models.product import Product

class ReportService:
    @staticmethod
    def get_sales_analytics(business_id, branch_id=None, start_date=None, end_date=None):
        query = Invoice.query.filter_by(business_id=business_id)
        if branch_id:
            query = query.filter_by(branch_id=branch_id)
        if start_date:
            query = query.filter(Invoice.invoice_date >= start_date)
        if end_date:
            query = query.filter(Invoice.invoice_date <= end_date)

        invoices = query.all()
        total_sales = sum(inv.grand_total for inv in invoices)
        total_taxable = sum(inv.taxable_value for inv in invoices)
        total_gst = sum(inv.cgst_amount + inv.sgst_amount + inv.igst_amount for inv in invoices)
        total_paid = sum(inv.paid_amount for inv in invoices)
        total_outstanding = sum(inv.balance_amount for inv in invoices)
        invoice_count = len(invoices)

        # Sales trend by date (last 7 or 30 days)
        trend_map = {}
        for inv in invoices:
            d_str = inv.invoice_date.strftime("%Y-%m-%d")
            trend_map[d_str] = trend_map.get(d_str, 0.0) + inv.grand_total

        trend = [{"date": k, "amount": round(v, 2)} for k, v in sorted(trend_map.items())]

        return {
            "total_sales": round(total_sales, 2),
            "total_taxable": round(total_taxable, 2),
            "total_gst": round(total_gst, 2),
            "total_paid": round(total_paid, 2),
            "total_outstanding": round(total_outstanding, 2),
            "invoice_count": invoice_count,
            "trend": trend
        }

    @staticmethod
    def get_profit_and_loss(business_id, branch_id=None, start_date=None, end_date=None):
        inv_q = Invoice.query.filter_by(business_id=business_id)
        exp_q = Expense.query.filter_by(business_id=business_id)
        pur_q = Purchase.query.filter_by(business_id=business_id)

        if branch_id:
            inv_q = inv_q.filter_by(branch_id=branch_id)
            exp_q = exp_q.filter_by(branch_id=branch_id)
            pur_q = pur_q.filter_by(branch_id=branch_id)

        if start_date:
            inv_q = inv_q.filter(Invoice.invoice_date >= start_date)
            exp_q = exp_q.filter(Expense.expense_date >= start_date)
            pur_q = pur_q.filter(Purchase.purchase_date >= start_date)

        if end_date:
            inv_q = inv_q.filter(Invoice.invoice_date <= end_date)
            exp_q = exp_q.filter(Expense.expense_date <= end_date)
            pur_q = pur_q.filter(Purchase.purchase_date <= end_date)

        total_sales = sum(i.grand_total for i in inv_q.all())
        total_purchases = sum(p.grand_total for p in pur_q.all())
        total_expenses = sum(e.amount for e in exp_q.all())

        gross_profit = total_sales - total_purchases
        net_profit = gross_profit - total_expenses
        profit_margin = round((net_profit / total_sales * 100), 2) if total_sales > 0 else 0.0

        return {
            "total_revenue": round(total_sales, 2),
            "cost_of_goods": round(total_purchases, 2),
            "gross_profit": round(gross_profit, 2),
            "total_expenses": round(total_expenses, 2),
            "net_profit": round(net_profit, 2),
            "profit_margin_percent": profit_margin
        }

    @staticmethod
    def get_gst_report(business_id, branch_id=None, start_date=None, end_date=None):
        # Outward supplies (GSTR-1)
        inv_q = Invoice.query.filter_by(business_id=business_id)
        # Inward supplies (Input Tax Credit)
        pur_q = Purchase.query.filter_by(business_id=business_id)

        if branch_id:
            inv_q = inv_q.filter_by(branch_id=branch_id)
            pur_q = pur_q.filter_by(branch_id=branch_id)

        if start_date:
            inv_q = inv_q.filter(Invoice.invoice_date >= start_date)
            pur_q = pur_q.filter(Purchase.purchase_date >= start_date)

        if end_date:
            inv_q = inv_q.filter(Invoice.invoice_date <= end_date)
            pur_q = pur_q.filter(Purchase.purchase_date <= end_date)

        invoices = inv_q.all()
        purchases = pur_q.all()

        outward_taxable = sum(i.taxable_value for i in invoices)
        outward_cgst = sum(i.cgst_amount for i in invoices)
        outward_sgst = sum(i.sgst_amount for i in invoices)
        outward_igst = sum(i.igst_amount for i in invoices)
        outward_total_tax = outward_cgst + outward_sgst + outward_igst

        inward_taxable = sum(p.taxable_value for p in purchases)
        inward_cgst = sum(p.cgst_amount for p in purchases)
        inward_sgst = sum(p.sgst_amount for p in purchases)
        inward_igst = sum(p.igst_amount for p in purchases)
        inward_itc_total = inward_cgst + inward_sgst + inward_igst

        net_tax_payable = max(0.0, outward_total_tax - inward_itc_total)

        return {
            "outward": {
                "taxable_value": round(outward_taxable, 2),
                "cgst": round(outward_cgst, 2),
                "sgst": round(outward_sgst, 2),
                "igst": round(outward_igst, 2),
                "total_tax": round(outward_total_tax, 2)
            },
            "inward_itc": {
                "taxable_value": round(inward_taxable, 2),
                "cgst": round(inward_cgst, 2),
                "sgst": round(inward_sgst, 2),
                "igst": round(inward_igst, 2),
                "total_tax": round(inward_itc_total, 2)
            },
            "net_gst_payable": round(net_tax_payable, 2)
        }

    @staticmethod
    def get_inventory_report(business_id, branch_id=None):
        prod_q = Product.query.filter_by(business_id=business_id, is_active=True).all()
        total_items = len(prod_q)
        total_valuation = 0.0
        low_stock_count = 0
        out_of_stock_count = 0
        items_summary = []

        for p in prod_q:
            stock = p.get_stock(branch_id)
            valuation = stock * p.purchase_price
            total_valuation += valuation

            if stock <= 0:
                out_of_stock_count += 1
            elif stock <= p.min_stock:
                low_stock_count += 1

            items_summary.append({
                "product_id": p.id,
                "name": p.name,
                "sku": p.sku,
                "unit": p.unit,
                "stock": stock,
                "min_stock": p.min_stock,
                "purchase_price": p.purchase_price,
                "valuation": round(valuation, 2),
                "status": "OUT_OF_STOCK" if stock <= 0 else ("LOW_STOCK" if stock <= p.min_stock else "IN_STOCK")
            })

        return {
            "total_items": total_items,
            "total_valuation": round(total_valuation, 2),
            "low_stock_count": low_stock_count,
            "out_of_stock_count": out_of_stock_count,
            "items": items_summary
        }
