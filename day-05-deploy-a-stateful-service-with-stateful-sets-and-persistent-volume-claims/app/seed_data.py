import random
from faker import Faker
from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models import Base, Users, Products, Carts, CartItems, Orders, OrderItems

fake = Faker()

def seed_users(db: Session, count=500):
    users = []
    for _ in range(count):
        user = Users(
            email=fake.unique.email(),
            password_hash="hashed_password",  # Replace with hash if needed
            name=fake.name()
        )
        db.add(user)
        users.append(user)
    db.commit()
    return users

def seed_products(db: Session, count=500):
    products = []
    for _ in range(count):
        product = Products(
            name=fake.word().capitalize(),
            price=round(random.uniform(5.0, 100.0), 2),
            stock=random.randint(10, 200),
            image_url=fake.image_url()
        )
        db.add(product)
        products.append(product)
    db.commit()
    return products

def seed_carts(db: Session, users, count=500):
    carts = []
    for i in range(count):
        if i % 2 == 0:
            cart = Carts(user_id=random.choice(users).id)
        else:
            cart = Carts(session_id=fake.uuid4())
        db.add(cart)
        carts.append(cart)
    db.commit()
    return carts

def seed_cart_items(db: Session, carts, products):
    for cart in carts:
        selected_products = random.sample(products, k=random.randint(1, 3))
        for product in selected_products:
            item = CartItems(
                cart_id=cart.id,
                product_id=product.id,
                quantity=random.randint(1, 5)
            )
            db.add(item)
    db.commit()

def seed_orders(db: Session, users, products, count=500):
    for _ in range(count):
        user = random.choice(users)
        order = Orders(
            user_id=user.id,
            total_amount=0.0,
            status="completed"
        )
        db.add(order)
        db.commit()
        db.refresh(order)

        total = 0.0
        selected_products = random.sample(products, k=random.randint(1, 3))
        for product in selected_products:
            quantity = random.randint(1, 3)
            total += product.price * quantity
            order_item = OrderItems(
                order_id=order.id,
                product_id=product.id,
                quantity=quantity,
                price_at_time=product.price
            )
            db.add(order_item)
            product.stock -= quantity
        order.total_amount = round(total, 2)
        db.commit()

def run():
    db = SessionLocal()
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    users = seed_users(db)
    products = seed_products(db)
    carts = seed_carts(db, users)
    seed_cart_items(db, carts, products)
    seed_orders(db, users, products)

    print("✅ Database seeded with fake data.")

if __name__ == "__main__":
    run()
