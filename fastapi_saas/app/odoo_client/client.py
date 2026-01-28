import xmlrpc.client
from typing import Any, List, Dict, Optional
from app.config import settings
from app.db import models
import logging
from .xmlrpc_pool import xmlrpc_pool

logger = logging.getLogger(__name__)

class OdooClient:
    def __init__(self) -> None:
        # key: "host:db:user" -> uid
        self._uids: dict[str, int] = {}

    def _get_uid(self, host: str, db: str, user: str, password: str) -> int:
        key = f"{host}:{db}:{user}"
        if key in self._uids:
            return self._uids[key]

        try:
            common = xmlrpc.client.ServerProxy(
                f"{host}/xmlrpc/2/common",
                allow_none=True,
            )
            uid = common.authenticate(db, user, password, {})
            if not uid:
                raise RuntimeError(
                    f"Failed to authenticate to Odoo: host={host}, db={db}, user={user}"
                )
            self._uids[key] = uid
            return uid
        except Exception as e:
            logger.error(
                "Odoo auth error: %s (host=%s, db=%s, user=%s)",
                e,
                host,
                db,
                user,
            )
            raise

    def execute_kw(
        self,
        company: models.Company,
        model: str,
        method: str,
        args: List[Any],
        kwargs: Dict[str, Any] | None = None,
    ):
        if kwargs is None:
            kwargs = {}

        user = settings.ODOO_SERVICE_USER
        password = settings.ODOO_SERVICE_PASSWORD

        host = company.odoo_host
        db = company.db_name

        try:
            uid = self._get_uid(host, db, user, password)
            models_proxy = xmlrpc.client.ServerProxy(
                f"{host}/xmlrpc/2/object",
                allow_none=True,
            )
            return models_proxy.execute_kw(db, uid, password, model, method, args, kwargs)
        except Exception as e:
            logger.error(f"Odoo RPC Error: {e} (model={model}, method={method})")
            raise

    async def execute_kw_async(self, *args, **kwargs):
        """Bridged to the hardened pool for high-performance calls"""
        return await xmlrpc_pool.execute_kw(*args, **kwargs)

odoo_client = OdooClient()
