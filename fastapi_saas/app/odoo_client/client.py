import xmlrpc.client
from typing import Any, List, Dict, Optional
from app.config import settings
from app.db import models
from sqlalchemy.orm import Session
import logging

logger = logging.getLogger(__name__)

class OdooClient:
    def __init__(self):
        self._connections = {}

    def get_connection(self, host: str, db: str, user: str, password: str):
        key = f"{host}:{db}:{user}"
        if key not in self._connections:
            common = xmlrpc.client.ServerProxy(f'{host}/xmlrpc/2/common')
            uid = common.authenticate(db, user, password, {})
            models = xmlrpc.client.ServerProxy(f'{host}/xmlrpc/2/object')
            self._connections[key] = (uid, models, password)
        return self._connections[key]

    def execute_kw(self, company: models.Company, model: str, method: str, args: List[Any], kwargs: Dict[str, Any] = None):
        if kwargs is None:
            kwargs = {}
            
        # Use service user for now, or map to specific user if needed
        user = settings.ODOO_SERVICE_USER
        password = settings.ODOO_SERVICE_PASSWORD
        
        try:
            uid, models_proxy, _ = self.get_connection(company.odoo_host, company.db_name, user, password)
            return models_proxy.execute_kw(company.db_name, uid, password, model, method, args, kwargs)
        except Exception as e:
            logger.error(f"Odoo RPC Error: {e}")
            raise e

odoo_client = OdooClient()
