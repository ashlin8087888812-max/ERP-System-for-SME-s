from sqlalchemy.orm import Session
from app.db import models
from app.config import settings
from typing import Optional

def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, email: str, full_name: str, company_id: int, password_hash: Optional[str] = None, google_sub: Optional[str] = None, role_id: Optional[int] = None) -> models.User:
    db_user = models.User(
        email=email,
        full_name=full_name,
        company_id=company_id,
        password_hash=password_hash,
        google_sub=google_sub
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    if role_id:
        # Assign role
        user_role = models.UserRole(user_id=db_user.id, role_id=role_id)
        db.add(user_role)
        db.commit()
        
    return db_user

def get_company_by_name(db: Session, name: str) -> Optional[models.Company]:
    return db.query(models.Company).filter(models.Company.name == name).first()

def create_company(db: Session, name: str, db_name: str, odoo_host: Optional[str] = None, plan_id: Optional[int] = None) -> models.Company:
    db_company = models.Company(
        name=name,
        db_name=db_name,
        odoo_host=odoo_host or settings.ODOO_HOST,
        plan_id=plan_id
    )
    db.add(db_company)
    db.commit()
    db.refresh(db_company)
    return db_company
