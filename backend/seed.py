from app import create_app
from app.extensions import db
from app.models.user import User, Role
from app.models.business import Business, Branch, BusinessSettings, PrinterSettings
from app.models.product import Category, Product
from app.models.party import Customer, Supplier
from app.models.inventory import BranchStock

def seed_database():
    app = create_app()
    with app.app_context():
        # Check if already seeded
        if User.query.filter_by(email="admin@bharatledger.com").first():
            print("Database already seeded.")
            return

        print("Seeding BharatLedger Industrial database...")

        # 1. Business
        biz = Business(
            name="Bharat Steels & Industrial Supplies",
            trade_name="BharatLedger Pro Mandi Store",
            gstin="27AAACB2234L1Z2",
            phone="+91 98230 12345",
            email="contact@bharatsteels.com",
            address="Plot No. 44, MIDC Industrial Area, Phase II",
            city="Pune",
            state="Maharashtra",
            pincode="411019"
        )
        db.session.add(biz)
        db.session.flush()

        # 2. Branches
        b1 = Branch(
            business_id=biz.id,
            name="Central Warehouse & Shop Floor",
            code="PUN-01",
            phone="+91 98230 12345",
            email="warehouse@bharatsteels.com",
            address="Plot No. 44, MIDC Phase II, Pune",
            city="Pune",
            state="Maharashtra",
            gstin=biz.gstin,
            is_head_office=True
        )
        b2 = Branch(
            business_id=biz.id,
            name="Mumbai Mandi Depot",
            code="MUM-01",
            phone="+91 98200 54321",
            email="mumbai@bharatsteels.com",
            address="Gala 12, Iron Market, Carnac Bunder",
            city="Mumbai",
            state="Maharashtra",
            gstin=biz.gstin,
            is_head_office=False
        )
        db.session.add_all([b1, b2])
        db.session.flush()

        # 3. Settings & Printer
        settings = BusinessSettings(
            business_id=biz.id,
            invoice_prefix="BL-INV-",
            next_invoice_number=1001,
            purchase_prefix="BL-PO-",
            next_purchase_number=501,
            default_tax_rate=18.0
        )
        printer = PrinterSettings(
            business_id=biz.id,
            branch_id=b1.id,
            printer_type="BLUETOOTH",
            printer_name="POS-80 Industrial Thermal",
            paper_size="80MM"
        )
        db.session.add_all([settings, printer])

        # 4. Users
        admin_user = User(
            business_id=biz.id,
            branch_id=b1.id,
            name="Mohit Sharma",
            email="admin@bharatledger.com",
            phone="+91 98230 12345",
            role=Role.ADMIN
        )
        admin_user.set_password("admin123")

        cashier_user = User(
            business_id=biz.id,
            branch_id=b1.id,
            name="Rahul Verma (Cashier)",
            email="cashier@bharatledger.com",
            phone="+91 98230 67890",
            role=Role.CASHIER
        )
        cashier_user.set_password("cashier123")

        db.session.add_all([admin_user, cashier_user])
        db.session.flush()

        # 5. Categories & Products
        c_valves = Category(business_id=biz.id, name="Industrial Valves", description="Cast iron & stainless steel valves")
        c_pipes = Category(business_id=biz.id, name="MS & GI Pipes", description="Heavy duty structural pipes")
        c_fasteners = Category(business_id=biz.id, name="High Tensile Fasteners", description="Grade 8.8 bolts, nuts and washers")
        c_welding = Category(business_id=biz.id, name="Welding Equipment", description="Electrodes, flux and welding accessories")
        db.session.add_all([c_valves, c_pipes, c_fasteners, c_welding])
        db.session.flush()

        products_data = [
            {
                "name": "Gate Valve 2 Inch CI Class 150",
                "sku": "VAL-GV-020",
                "barcode": "890123456701",
                "category_id": c_valves.id,
                "unit": "PCS",
                "purchase_price": 1250.0,
                "selling_price": 1650.0,
                "mrp": 1850.0,
                "gst_rate": 18.0,
                "hsn_sac": "8481",
                "min_stock": 15.0,
                "stock_b1": 45.0,
                "stock_b2": 20.0
            },
            {
                "name": "Ball Valve 1 Inch SS 304 Threaded",
                "sku": "VAL-BV-010",
                "barcode": "890123456702",
                "category_id": c_valves.id,
                "unit": "PCS",
                "purchase_price": 420.0,
                "selling_price": 580.0,
                "mrp": 650.0,
                "gst_rate": 18.0,
                "hsn_sac": "8481",
                "min_stock": 25.0,
                "stock_b1": 80.0,
                "stock_b2": 35.0
            },
            {
                "name": "MS Seamless Pipe 2.5 Inch SCH 40 (6m)",
                "sku": "PIP-MS-025",
                "barcode": "890123456703",
                "category_id": c_pipes.id,
                "unit": "MTR",
                "purchase_price": 820.0,
                "selling_price": 1100.0,
                "mrp": 1250.0,
                "gst_rate": 18.0,
                "hsn_sac": "7304",
                "min_stock": 50.0,
                "stock_b1": 180.0,
                "stock_b2": 60.0
            },
            {
                "name": "High Tensile Hex Bolt M16 x 65mm Gr 8.8",
                "sku": "FAS-HT-1665",
                "barcode": "890123456704",
                "category_id": c_fasteners.id,
                "unit": "BOX",
                "purchase_price": 350.0,
                "selling_price": 490.0,
                "mrp": 550.0,
                "gst_rate": 18.0,
                "hsn_sac": "7318",
                "min_stock": 20.0,
                "stock_b1": 6.0,  # Low stock test item!
                "stock_b2": 10.0
            },
            {
                "name": "Mild Steel Welding Electrode E6013 3.15mm",
                "sku": "WLD-EL-315",
                "barcode": "890123456705",
                "category_id": c_welding.id,
                "unit": "BOX",
                "purchase_price": 280.0,
                "selling_price": 390.0,
                "mrp": 450.0,
                "gst_rate": 18.0,
                "hsn_sac": "8311",
                "min_stock": 30.0,
                "stock_b1": 110.0,
                "stock_b2": 40.0
            }
        ]

        for p_data in products_data:
            p = Product(
                business_id=biz.id,
                category_id=p_data["category_id"],
                name=p_data["name"],
                sku=p_data["sku"],
                barcode=p_data["barcode"],
                unit=p_data["unit"],
                purchase_price=p_data["purchase_price"],
                selling_price=p_data["selling_price"],
                mrp=p_data["mrp"],
                gst_rate=p_data["gst_rate"],
                hsn_sac=p_data["hsn_sac"],
                min_stock=p_data["min_stock"]
            )
            db.session.add(p)
            db.session.flush()

            # Assign stock
            s1 = BranchStock(branch_id=b1.id, product_id=p.id, quantity=p_data["stock_b1"])
            s2 = BranchStock(branch_id=b2.id, product_id=p.id, quantity=p_data["stock_b2"])
            db.session.add_all([s1, s2])

        # 6. Customers
        cust1 = Customer(
            business_id=biz.id,
            name="Apex Engineering & Fabricators",
            company_name="Apex Engg Pvt Ltd",
            phone="+91 98901 23456",
            email="purchase@apexengineering.com",
            gstin="27AAACA9876Q1ZA",
            address="Plot 10, Bhosari MIDC, Pune",
            city="Pune",
            state="Maharashtra",
            credit_limit=250000.0,
            opening_balance=15000.0,
            current_balance=15000.0
        )
        cust2 = Customer(
            business_id=biz.id,
            name="Maharashtra Sugar Mills Ltd",
            company_name="Maharashtra Sugar Mills Ltd",
            phone="+91 98220 98765",
            email="stores@maharsugarmills.com",
            gstin="27AAACM4455K1Z8",
            address="Sugar Factory Road, Baramati",
            city="Baramati",
            state="Maharashtra",
            credit_limit=500000.0,
            opening_balance=0.0,
            current_balance=0.0
        )
        db.session.add_all([cust1, cust2])

        # 7. Suppliers
        sup1 = Supplier(
            business_id=biz.id,
            name="Jindal Steel & Tubing Corporation",
            company_name="Jindal Steel & Tubes Ltd",
            phone="+91 98110 54321",
            email="sales@jindalsteeltubes.com",
            gstin="07AAACJ1234F1ZX",
            address="Barakhamba Road, Connaught Place",
            city="New Delhi",
            state="Delhi",
            opening_balance=45000.0,
            current_payable=45000.0
        )
        sup2 = Supplier(
            business_id=biz.id,
            name="Audco Valve Distributors",
            company_name="Audco Flow Control India",
            phone="+91 98400 11223",
            email="orders@audcoflow.com",
            gstin="33AAACA3322N1Z1",
            address="Mount Road, Guindy",
            city="Chennai",
            state="Tamil Nadu",
            opening_balance=0.0,
            current_payable=0.0
        )
        db.session.add_all([sup1, sup2])

        db.session.commit()
        print("Seeding completed successfully.")

if __name__ == "__main__":
    seed_database()
