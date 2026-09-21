import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from app.config import Config

class PdfService:
    @staticmethod
    def generate_invoice_pdf(invoice):
        filename = f"Invoice_{invoice.invoice_number.replace('/', '_')}.pdf"
        filepath = os.path.join(Config.INVOICE_PDF_DIR, filename)

        doc = SimpleDocTemplate(
            filepath,
            pagesize=A4,
            rightMargin=30,
            leftMargin=30,
            topMargin=30,
            bottomMargin=30
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'TitleStyle',
            parent=styles['Heading1'],
            fontSize=18,
            textColor=colors.HexColor('#0F172A'),
            spaceAfter=6
        )
        subtitle_style = ParagraphStyle(
            'SubStyle',
            parent=styles['Normal'],
            fontSize=10,
            textColor=colors.HexColor('#64748B'),
            spaceAfter=12
        )
        normal_style = styles['Normal']
        normal_style.fontSize = 9
        bold_style = ParagraphStyle(
            'BoldStyle',
            parent=normal_style,
            fontName='Helvetica-Bold'
        )

        story = []

        # Header with Company Name & Tax Invoice Title
        biz_name = invoice.customer.business_id if invoice.customer else "Bharat Industrial"
        from app.models.business import Business
        biz = Business.query.get(invoice.business_id)

        header_data = [
            [
                Paragraph(f"<b>{biz.name if biz else 'BharatLedger Industrial'}</b><br/>{biz.address if biz else 'Shop floor / Mandi'}<br/>GSTIN: {biz.gstin if biz else '27AABCB1234F1Z1'}<br/>Phone: {biz.phone if biz else '+91 98765 43210'}", normal_style),
                Paragraph(f"<font size=16 color='#2563EB'><b>TAX INVOICE</b></font><br/><br/><b>Invoice No:</b> {invoice.invoice_number}<br/><b>Date:</b> {invoice.invoice_date}<br/><b>Due Date:</b> {invoice.due_date}", normal_style)
            ]
        ]
        header_table = Table(header_data, colWidths=[300, 230])
        header_table.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ]))
        story.append(header_table)
        story.append(Spacer(1, 10))

        # Bill To section
        cust = invoice.customer
        bill_to_data = [
            [
                Paragraph("<b>BILL TO:</b>", bold_style),
                Paragraph("<b>PLACE OF SUPPLY:</b>", bold_style)
            ],
            [
                Paragraph(f"<b>{cust.name}</b><br/>{cust.company_name or ''}<br/>{cust.address or ''}<br/>Phone: {cust.phone}<br/>GSTIN: {cust.gstin or 'URP'}", normal_style),
                Paragraph(f"{cust.state or 'Maharashtra'} (State Code: 27)<br/>Payment Terms: {invoice.payment_terms}<br/>Status: <b>{invoice.status}</b>", normal_style)
            ]
        ]
        bill_to_table = Table(bill_to_data, colWidths=[300, 230])
        bill_to_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#F1F5F9')),
            ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#E2E8F0')),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('PADDING', (0,0), (-1,-1), 6),
        ]))
        story.append(bill_to_table)
        story.append(Spacer(1, 15))

        # Line items table
        item_headers = ["#", "Item Description", "HSN/SAC", "Qty", "Rate (₹)", "GST %", "Tax (₹)", "Total (₹)"]
        items_data = [item_headers]

        idx = 1
        for itm in invoice.items:
            tax = itm.cgst_amount + itm.sgst_amount + itm.igst_amount
            items_data.append([
                str(idx),
                itm.product_name,
                itm.hsn_sac,
                f"{itm.quantity} {itm.unit}",
                f"{itm.unit_price:.2f}",
                f"{itm.gst_rate:.1f}%",
                f"{tax:.2f}",
                f"{itm.total_amount:.2f}"
            ])
            idx += 1

        items_table = Table(items_data, colWidths=[25, 175, 55, 50, 65, 45, 55, 65])
        items_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0F172A')),
            ('TEXTCOLOR', (0,0), (-1,0), colors.white),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 8),
            ('ALIGN', (0,0), (0,-1), 'CENTER'),
            ('ALIGN', (3,0), (-1,-1), 'RIGHT'),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
            ('PADDING', (0,0), (-1,-1), 5),
        ]))
        story.append(items_table)
        story.append(Spacer(1, 12))

        # Summary & Tax breakdown table
        summary_data = [
            ["Taxable Subtotal:", f"₹ {invoice.taxable_value:.2f}"],
            ["CGST Amount:", f"₹ {invoice.cgst_amount:.2f}"],
            ["SGST Amount:", f"₹ {invoice.sgst_amount:.2f}"],
            ["IGST Amount:", f"₹ {invoice.igst_amount:.2f}"],
            ["Round Off:", f"₹ {invoice.round_off:.2f}"],
            ["Grand Total:", f"₹ {invoice.grand_total:.2f}"],
            ["Paid Amount:", f"₹ {invoice.paid_amount:.2f}"],
            ["Balance Due:", f"₹ {invoice.balance_amount:.2f}"]
        ]
        summary_table = Table(summary_data, colWidths=[120, 90], hAlign='RIGHT')
        summary_table.setStyle(TableStyle([
            ('FONTNAME', (0,5), (-1,5), 'Helvetica-Bold'),
            ('BACKGROUND', (0,5), (-1,5), colors.HexColor('#EFF6FF')),
            ('TEXTCOLOR', (0,5), (-1,5), colors.HexColor('#2563EB')),
            ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
            ('PADDING', (0,0), (-1,-1), 3),
        ]))
        story.append(summary_table)
        story.append(Spacer(1, 15))

        # Terms & Conditions and Footer Attribution
        terms_text = (
            "<b>Terms & Conditions:</b><br/>"
            "1. Goods once sold will not be returned without original cash memo.<br/>"
            "2. Subject to local state jurisdiction.<br/>"
            "<br/><b>© NexvoraTech LLP — Developed by Mohit</b>"
        )
        story.append(Paragraph(terms_text, normal_style))

        doc.build(story)
        return filepath
