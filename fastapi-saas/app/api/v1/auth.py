from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.db import crud, models
from app.db.base import get_db
from app.core import security, jwt, google_oauth
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

class GoogleLoginRequest(BaseModel):
    token: str
    company_name: Optional[str] = None # Required for signup
    company_db_name: Optional[str] = None # Required for signup
    odoo_host: Optional[str] = None # Required for signup

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

@router.post("/auth/google", response_model=Token)
def google_login(login_data: GoogleLoginRequest, db: Session = Depends(get_db)):
    id_info = google_oauth.verify_google_token(login_data.token)
    if not id_info:
        raise HTTPException(status_code=400, detail="Invalid Google Token")
    
    email = id_info['email']
    user = crud.get_user_by_email(db, email=email)
    
    if not user:
        # Signup flow if company details provided
        if login_data.company_name and login_data.company_db_name and login_data.odoo_host:
             # Create Company
            company = crud.create_company(
                db=db,
                name=login_data.company_name,
                db_name=login_data.company_db_name,
                odoo_host=login_data.odoo_host
            )
            # Create User
            user = crud.create_user(
                db=db,
                email=email,
                full_name=id_info.get('name', ''),
                company_id=company.id,
                google_sub=id_info['sub']
            )
        else:
             raise HTTPException(status_code=400, detail="User not found. Please provide company details to signup.")
    
    company = user.company
    access_token_expires = jwt.timedelta(minutes=settings.JWT_EXP_MINUTES)
    access_token = jwt.create_access_token(
        data={"sub": str(user.id), "email": user.email, "company_id": company.id, "db_name": company.db_name, "role": "admin"},
        expires_delta=access_token_expires,
    )
    return {"access_token": access_token, "token_type": "bearer"}
