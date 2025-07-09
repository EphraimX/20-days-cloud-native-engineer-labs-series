from pydantic import BaseModel
from typing import List

class UserCreate(BaseModel):
    email: str
    password_hash: str
    name: str

class UserOut(BaseModel):
    id: int
    email: str
    name: str
    class Config:
        orm_mode = True

class ProductOut(BaseModel):
    id: int
    name: str
    price: float
    stock: int
    image_url: str
    class Config:
        orm_mode = True

class CartItemCreate(BaseModel):
    product_id: int
    quantity: int

class CartItemOut(CartItemCreate):
    id: int
    class Config:
        orm_mode = True

class CartOut(BaseModel):
    id: int
    cart_items: List[CartItemOut]
    class Config:
        orm_mode = True

class OrderCreate(BaseModel):
    user_id: int
    cart_id: int

class OrderOut(BaseModel):
    id: int
    total_amount: float
    status: str
    class Config:
        orm_mode = True
