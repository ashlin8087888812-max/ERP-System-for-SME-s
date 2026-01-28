import asyncio
import logging
import xmlrpc.client
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta

from app.config import settings
from app.db import models

logger = logging.getLogger(__name__)

class XMLRPCPool:
    """
    Hardened XML-RPC Client with:
    - Async ThreadPoolExecutor for non-blocking I/O
    - Circuit Breaker pattern to fail fast
    - Per-tenant connection caching
    - Strict timeout budgets
    """
    
    def __init__(self, max_workers: int = 20):
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        self._uids: Dict[str, dict] = {}  # "host:db:user" -> {"uid": int, "expiry": datetime}
        self._failure_count: Dict[str, int] = {} # "host" -> count
        self._last_failure: Dict[str, datetime] = {} # "host" -> time
        
        # Circuit Breaker Config
        self.FAILURE_THRESHOLD = 5
        self.RECOVERY_TIMEOUT = 30 # seconds

    def _is_circuit_open(self, host: str) -> bool:
        if self._failure_count.get(host, 0) >= self.FAILURE_THRESHOLD:
            last_fail = self._last_failure.get(host)
            if last_fail and (datetime.now() - last_fail).total_seconds() < self.RECOVERY_TIMEOUT:
                return True
            # Allow half-open state
            self._failure_count[host] = self.FAILURE_THRESHOLD - 1
        return False

    def _record_failure(self, host: str):
        self._failure_count[host] = self._failure_count.get(host, 0) + 1
        self._last_failure[host] = datetime.now()

    def _record_success(self, host: str):
        self._failure_count[host] = 0

    def _get_uid(self, host: str, db: str, user: str, password: str) -> int:
        key = f"{host}:{db}:{user}"
        cached = self._uids.get(key)
        if cached and cached["expiry"] > datetime.now():
            return cached["uid"]

        try:
            common = xmlrpc.client.ServerProxy(f"{host}/xmlrpc/2/common", allow_none=True)
            # Standard Odoo auth timeout is usually fast
            uid = common.authenticate(db, user, password, {})
            if not uid:
                raise RuntimeError(f"Authentication failed for {user} on {db}")
            
            self._uids[key] = {
                "uid": uid,
                "expiry": datetime.now() + timedelta(hours=1)
            }
            return uid
        except Exception as e:
            logger.error(f"Odoo Auth Error: {e}")
            raise

    def sync_execute_kw(
        self,
        company: models.Company,
        model: str,
        method: str,
        args: List[Any],
        kwargs: Dict[str, Any],
        user: Optional[str] = None,
        password: Optional[str] = None
    ):
        host = company.odoo_host
        db = company.db_name
        user = user or settings.ODOO_SERVICE_USER
        password = password or settings.ODOO_SERVICE_PASSWORD

        if self._is_circuit_open(host):
            raise RuntimeError(f"Circuit open for host {host}")

        try:
            uid = self._get_uid(host, db, user, password)
            proxy = xmlrpc.client.ServerProxy(f"{host}/xmlrpc/2/object", allow_none=True)
            result = proxy.execute_kw(db, uid, password, model, method, args, kwargs)
            self._record_success(host)
            return result
        except Exception as e:
            self._record_failure(host)
            logger.error(f"XML-RPC execution error: {e}")
            raise

    async def execute_kw(
        self,
        company: models.Company,
        model: str,
        method: str,
        args: List[Any],
        kwargs: Optional[Dict[str, Any]] = None,
        timeout: float = 5.0 # 5.0s budget
    ) -> Any:
        if kwargs is None:
            kwargs = {}
            
        loop = asyncio.get_event_loop()
        try:
            return await asyncio.wait_for(
                loop.run_in_executor(
                    self.executor,
                    self.sync_execute_kw,
                    company, model, method, args, kwargs
                ),
                timeout=timeout
            )
        except asyncio.TimeoutError:
            logger.warning(f"Timeout budget exceeded for {model}.{method} on {company.odoo_host}")
            raise

xmlrpc_pool = XMLRPCPool()
