from google.oauth2 import id_token
from google.auth.transport import requests
from app.config import settings
from typing import Optional, Dict, Any

def verify_google_token(token: str) -> Optional[Dict[str, Any]]:
    try:
        id_info = id_token.verify_oauth2_token(token, requests.Request(), settings.GOOGLE_CLIENT_ID)
        return id_info
    except ValueError:
        # Invalid token
        return None
