from app.db.base import SessionLocal
from app.db import crud
import bcrypt

db = SessionLocal()

# Check if test user exists
user = crud.get_user_by_email(db, 'test@example.com')

if not user:
    # Create test company
    company = crud.get_company_by_name(db, 'Test Company')
    if not company:
        company = crud.create_company(
            db=db,
            name='Test Company',
            db_name='test_db',
            odoo_host='http://localhost:8068'
        )
    
    # Create password hash directly with bcrypt
    password_hash = bcrypt.hashpw('password123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    # Create test user
    user = crud.create_user(
        db=db,
        email='test@example.com',
        full_name='Test User',
        company_id=company.id,
        password_hash=password_hash
    )
    print(f'Created test user: {user.email}')
else:
    print(f'Test user already exists: {user.email}')

db.close()
