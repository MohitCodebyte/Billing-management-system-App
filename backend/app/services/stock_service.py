from datetime import datetime
from app.extensions import db
from app.models.inventory import BranchStock, StockMovement, StockMovementType
from app.models.product import Product
from app.models.notification import Notification

class StockService:
    @staticmethod
    def adjust_stock(branch_id, product_id, quantity, movement_type, reference_type="MANUAL",
                     reference_id=None, notes="", user_id=None):
        stock = BranchStock.query.filter_by(branch_id=branch_id, product_id=product_id).first()
        product = Product.query.get(product_id)
        if not product:
            raise ValueError(f"Product {product_id} not found")

        if not stock:
            stock = BranchStock(branch_id=branch_id, product_id=product_id, quantity=0.0)
            db.session.add(stock)

        prev_qty = stock.quantity

        if movement_type in [StockMovementType.IN, StockMovementType.RETURN]:
            new_qty = prev_qty + quantity
        elif movement_type in [StockMovementType.OUT, StockMovementType.DAMAGE]:
            if prev_qty < quantity and movement_type == StockMovementType.OUT:
                # Warning or allowance depending on business mode, but let's record and flag
                pass
            new_qty = max(0.0, prev_qty - quantity)
        elif movement_type == StockMovementType.ADJUSTMENT:
            new_qty = quantity
            quantity = abs(new_qty - prev_qty)
        else:
            new_qty = prev_qty

        stock.quantity = round(new_qty, 2)

        movement = StockMovement(
            branch_id=branch_id,
            product_id=product_id,
            movement_type=movement_type,
            quantity=round(quantity, 2),
            previous_quantity=round(prev_qty, 2),
            new_quantity=round(new_qty, 2),
            reference_type=reference_type,
            reference_id=reference_id,
            notes=notes,
            created_by_user_id=user_id
        )
        db.session.add(movement)

        # Trigger low stock notification if below threshold
        if stock.quantity <= product.min_stock:
            existing_alert = Notification.query.filter_by(
                business_id=product.business_id,
                reference_id=product.id,
                type="LOW_STOCK",
                is_read=False
            ).first()
            if not existing_alert:
                alert = Notification(
                    business_id=product.business_id,
                    branch_id=branch_id,
                    type="LOW_STOCK",
                    title="Low Stock Alert",
                    message=f"Product '{product.name}' (SKU: {product.sku}) has only {stock.quantity} {product.unit} remaining.",
                    reference_type="PRODUCT",
                    reference_id=product.id
                )
                db.session.add(alert)

        return stock, movement
