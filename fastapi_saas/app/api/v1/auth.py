from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.db import crud, models
from app.db.base import get_db
from app.core import security, jwt
from app.config import settings

router = APIRouter()

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    company_name: str
    company_db_name: str
    odoo_host: str

class Token(BaseModel):
    access_token: str
    token_type: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


@router.post("/signup", response_model=Token)
def signup(user_in: UserCreate, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system.",
        )
    
    company = crud.get_company_by_name(db, name=user_in.company_name)
    if company:
        raise HTTPException(
            status_code=400,
            detail="The company with this name already exists.",
        )
        
    # Create Company
    company = crud.create_company(
        db=db,
        name=user_in.company_name,
        db_name=user_in.company_db_name,
        odoo_host=user_in.odoo_host
    )
    
    # Create User
    user = crud.create_user(
        db=db,
        email=user_in.email,
        full_name=user_in.full_name,
        company_id=company.id,
        password_hash=security.get_password_hash(user_in.password)
    )
    
    # Generate JWT
    access_token_expires = jwt.timedelta(minutes=settings.JWT_EXP_MINUTES)
    access_token = jwt.create_access_token(
        data={"sub": str(user.id), "email": user.email, "company_id": company.id, "db_name": company.db_name, "role": "admin"},
        expires_delta=access_token_expires,
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, email=login_data.email)
    if not user or not security.verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    company = user.company
    
    access_token_expires = jwt.timedelta(minutes=settings.JWT_EXP_MINUTES)
    access_token = jwt.create_access_token(
        data={"sub": str(user.id), "email": user.email, "company_id": company.id, "db_name": company.db_name, "role": "admin"}, # TODO: Fetch actual role
        expires_delta=access_token_expires,
    )
    return {"access_token": access_token, "token_type": "bearer"}

