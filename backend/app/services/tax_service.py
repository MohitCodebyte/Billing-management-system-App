class TaxService:
    @staticmethod
    def calculate_item_tax(quantity, unit_price, discount_percent=0.0, gst_rate=18.0, is_interstate=False):
        gross_amount = quantity * unit_price
        discount_amount = gross_amount * (discount_percent / 100.0)
        taxable_amount = gross_amount - discount_amount

        if is_interstate:
            igst_amount = taxable_amount * (gst_rate / 100.0)
            cgst_amount = 0.0
            sgst_amount = 0.0
        else:
            igst_amount = 0.0
            cgst_amount = taxable_amount * ((gst_rate / 2.0) / 100.0)
            sgst_amount = taxable_amount * ((gst_rate / 2.0) / 100.0)

        total_tax = igst_amount + cgst_amount + sgst_amount
        total_amount = taxable_amount + total_tax

        return {
            "quantity": float(quantity),
            "unit_price": round(float(unit_price), 2),
            "discount_amount": round(float(discount_amount), 2),
            "taxable_amount": round(float(taxable_amount), 2),
            "gst_rate": float(gst_rate),
            "cgst_amount": round(float(cgst_amount), 2),
            "sgst_amount": round(float(sgst_amount), 2),
            "igst_amount": round(float(igst_amount), 2),
            "total_tax": round(float(total_tax), 2),
            "total_amount": round(float(total_amount), 2)
        }

    @staticmethod
    def calculate_invoice_totals(items, additional_charges=0.0, global_discount=0.0, is_interstate=False):
        subtotal = sum(item["quantity"] * item["unit_price"] for item in items)
        item_discounts = sum(item.get("discount_amount", 0.0) for item in items)
        total_discount = item_discounts + global_discount
        taxable_value = sum(item["taxable_amount"] for item in items) - global_discount
        taxable_value = max(0.0, taxable_value)

        cgst_total = sum(item.get("cgst_amount", 0.0) for item in items)
        sgst_total = sum(item.get("sgst_amount", 0.0) for item in items)
        igst_total = sum(item.get("igst_amount", 0.0) for item in items)

        net_before_round = taxable_value + cgst_total + sgst_total + igst_total + additional_charges
        grand_total = round(net_before_round)
        round_off = round(grand_total - net_before_round, 2)

        return {
            "subtotal": round(subtotal, 2),
            "discount_amount": round(total_discount, 2),
            "taxable_value": round(taxable_value, 2),
            "cgst_amount": round(cgst_total, 2),
            "sgst_amount": round(sgst_total, 2),
            "igst_amount": round(igst_total, 2),
            "additional_charges": round(additional_charges, 2),
            "round_off": round_off,
            "grand_total": float(grand_total)
        }
