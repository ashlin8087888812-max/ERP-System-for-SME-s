
import asyncio
import logging
from app.db.base import SessionLocal
from app.db import models
from app.odoo_client.client import odoo_client
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def make_admin():
    db = SessionLocal()
    try:
        # 1. Get user and company info
        user = db.query(models.User).filter(models.User.email == 'test@example.com').first()
        if not user:
            print("User test@example.com not found")
            return
        
        # 0. Assign 'admin' role in FastAPI DB
        admin_role = db.query(models.Role).filter(models.Role.name == 'admin').first()
        if not admin_role:
            print("Role 'admin' not found in FastAPI DB, creating it...")
            admin_role = models.Role(name='admin', permissions={"all": True})
            db.add(admin_role)
            db.commit()
            db.refresh(admin_role)
        
        if admin_role not in user.roles:
            user.roles.append(admin_role)
            db.commit()
            print(f"✅ Assigned 'admin' role to {user.email} in FastAPI")
        else:
            print(f"User {user.email} already has 'admin' role in FastAPI")

        company = user.company
        # Use global ODOO_HOST from settings
        company.odoo_host = settings.ODOO_HOST
        
        print(f"User: {user.email} (ID: {user.id})")
        print(f"Company: {company.name} (ID: {company.id}, DB: {company.db_name})")
        print(f"Targeting Odoo at: {settings.ODOO_HOST}")

        # 2. Ensure Odoo User exists and is an admin
        print(f"Checking if Odoo user {user.email} exists...")
        user_data = await odoo_client.execute_kw_async(
            company,
            "res.users",
            "search_read",
            [["|", ("login", "=", user.email), ("email", "=", user.email)]],
            {"fields": ["id", "login", "email"], "limit": 1},
            timeout=30.0
        )

        if not user_data:
            print(f"User {user.email} not found in Odoo. Creating...")
            # Create user in Odoo
            # password defaults to 'password123' to match what we created in FastAPI
            odoo_user_id = await odoo_client.execute_kw_async(
                company,
                "res.users",
                "create",
                [{
                    "name": user.full_name or "Test User",
                    "login": user.email,
                    "email": user.email,
                    "password": "password123",
                }],
                timeout=30.0
            )
            print(f"✅ Created Odoo user {user.email} (ID: {odoo_user_id})")
        else:
            odoo_user_id = user_data[0]["id"]
            print(f"Found existing Odoo user {user.email} (ID: {odoo_user_id})")

        # 3. Find group id for Admin (base.group_system) using search_read
        print("Finding Odoo Admin group ID using search_read...")
        data = await odoo_client.execute_kw_async(
            company,
            "ir.model.data",
            "search_read",
            [[("module", "=", "base"), ("name", "=", "group_system")]],
            {"fields": ["res_id"], "limit": 1},
            timeout=30.0
        )
        
        if not data:
            print("Error: Could not find base.group_system in ir.model.data")
            return
            
        group_id = data[0]["res_id"]
        print(f"Group ID for base.group_system: {group_id}")

        # 4. Add group to user
        # Note: In Odoo 19, the field is 'group_ids' (singular group), 
        # and 'groups_id' alias might be removed.
        print(f"Adding group {group_id} to Odoo user {odoo_user_id}...")
        await odoo_client.execute_kw_async(
            company,
            "res.users",
            "write",
            [[odoo_user_id], {"group_ids": [(4, group_id)]}],
            timeout=30.0
        )
        print(f"✅ User '{user.email}' is now an admin in Odoo")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(make_admin())
