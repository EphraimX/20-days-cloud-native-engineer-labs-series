from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import SessionLocal, engine
from models import Base, Users, Products, Carts, CartItems, Orders, OrderItems
from schemas import *

app = FastAPI()

Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/healthcheck")
def health():
    return {"status": 200, "message": "API Up and Running"}

@app.post("/users/", response_model=UserOut)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    if db.query(Users).filter(Users.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    new_user = Users(**user.dict())
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.get("/products/", response_model=List[ProductOut])
def list_products(db: Session = Depends(get_db)):
    return db.query(Products).all()

@app.get("/products/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(Products).get(product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@app.post("/cart/{cart_id}/items", response_model=CartOut)
def add_item_to_cart(cart_id: int, item: CartItemCreate, db: Session = Depends(get_db)):
    cart = db.query(Carts).get(cart_id)
    if not cart:
        raise HTTPException(status_code=404, detail="Cart not found")

    existing = db.query(CartItems).filter_by(cart_id=cart_id, product_id=item.product_id).first()
    if existing:
        existing.quantity += item.quantity
    else:
        db.add(CartItems(cart_id=cart_id, **item.dict()))
    db.commit()
    return cart

@app.post("/orders/", response_model=OrderOut)
def checkout(order: OrderCreate, db: Session = Depends(get_db)):
    cart = db.query(Carts).get(order.cart_id)
    if not cart:
        raise HTTPException(status_code=404, detail="Cart not found")

    items = db.query(CartItems).filter_by(cart_id=order.cart_id).all()
    total = sum(item.quantity * db.query(Products).get(item.product_id).price for item in items)

    new_order = Orders(user_id=order.user_id, total_amount=total, status="pending")
    db.add(new_order)
    db.commit()
    db.refresh(new_order)

    for item in items:
        product = db.query(Products).get(item.product_id)
        db.add(OrderItems(order_id=new_order.id, product_id=item.product_id, quantity=item.quantity, price_at_time=product.price))
        product.stock -= item.quantity
        db.delete(item)
    db.commit()

    return new_order
