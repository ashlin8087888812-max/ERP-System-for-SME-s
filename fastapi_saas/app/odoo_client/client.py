#odoo_client/client.py
import xmlrpc.client
from typing import Any, List, Dict
from app.config import settings
from app.db import models
import logging

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

            # 🔑 NEW: create a fresh ServerProxy for *each* call
            models_proxy = xmlrpc.client.ServerProxy(
                f"{host}/xmlrpc/2/object",
                allow_none=True,
            )

            return models_proxy.execute_kw(db, uid, password, model, method, args, kwargs)

        except Exception as e:
            logger.error(
                "Odoo RPC Error: %s (model=%s, method=%s, args=%s, kwargs=%s)",
                e,
                model,
                method,
                args,
                kwargs,
            )
            # Re-raise so FastAPI can turn it into a 500
            raise


odoo_client = OdooClient()
