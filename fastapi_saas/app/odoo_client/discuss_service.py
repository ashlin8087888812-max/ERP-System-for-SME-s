import logging
from typing import List, Optional, Any
from datetime import datetime

from app.db import models
from app.odoo_client.client import odoo_client
from app.cache.discuss_cache import discuss_cache
from app.schemas.discuss import ChannelOut, MessageOut, MemberOut, AttachmentOut
from app.core.logging import logger

class DiscussService:
    """
    Production-grade Discuss Service with:
    - Membership enforcement
    - Redis write-through caching
    - XML-RPC pooling
    - HTML sanitization placeholders
    """

    async def get_user_partner_id(self, company: models.Company, local_user_id: int, email: str) -> int:
        email_clean = (email or "").strip().lower()
        cache_key = f"user_partner_v4:{company.id}:{email_clean}"

        cached = await discuss_cache.get(company.id, "res.user.partner", cache_key)
        if cached:
            return int(cached)

        try:
            # Search res.users by login OR email
            user_data = await odoo_client.execute_kw_async(
                company,
                "res.users",
                "search_read",
                [[ "|", ("login", "ilike", email_clean), ("email", "ilike", email_clean) ]],
                {"fields": ["partner_id", "login", "email"], "limit": 1},
            )

            if user_data and user_data[0].get("partner_id"):
                pid = user_data[0]["partner_id"][0]
                await discuss_cache.set(company.id, "res.user.partner", cache_key, pid, ttl=3600)
                return pid

            # Fallback: search res.partner by email
            partner_data = await odoo_client.execute_kw_async(
                company,
                "res.partner",
                "search_read",
                [[("email", "ilike", email_clean)]],
                {"fields": ["id", "email", "name"], "limit": 1},
            )

            if partner_data:
                pid = partner_data[0]["id"]
                await discuss_cache.set(company.id, "res.user.partner", cache_key, pid, ttl=3600)
                return pid

            logger.error(f"FATAL: Could not resolve partner_id for email={email_clean} local_user_id={local_user_id}")
            return 0

        except Exception as e:
            logger.error(f"Odoo resolution error for {email_clean}: {e}")
            return 0

    async def get_channels(self, company: models.Company, partner_id: int) -> List[ChannelOut]:
        """Fetch all channels (inclusive of membership and public access)"""
        if not partner_id:
            return []

        # Try cache first
        cached = await discuss_cache.get(company.id, "channels", partner_id)
        if cached:
            return [ChannelOut(**c) for c in cached]

        logger.info(f"[Discuss] get_channels partner_id={partner_id}")

        # In Odoo 19, 'public' is replaced by 'channel_type'
        # Fetches member channels OR joinable 'channel' type channels.
        domain = [
            '|',
            ('channel_member_ids.partner_id', '=', partner_id),
            ('channel_type', '=', 'channel')
        ]
        
        fields = ["id", "name", "channel_type", "description", "uuid", "member_count", "message_count", "last_interest_dt", "image_128"]
        
        try:
            channels_raw = await odoo_client.execute_kw_async(
                company, "discuss.channel", "search_read",
                [domain], {"fields": fields, "order": "last_interest_dt desc"}
            )
            
            logger.info(f"Odoo resolved {len(channels_raw)} channels for partner {partner_id}")
            
            # Diagnostic count for monitoring
            total_count = await odoo_client.execute_kw_async(company, "discuss.channel", "search_count", [[]])
            logger.info(f"Total Odoo channels accessible to API user: {total_count}")

            result: List[ChannelOut] = []

            for c in channels_raw:
                img = c.get("image_128")
                avatar = img if isinstance(img, str) and img else None

                result.append(ChannelOut(
                    id=c["id"],
                    name=c.get("name") or "Unnamed",
                    type=c.get("channel_type") or "channel",
                    description=c.get("description") or None,
                    uuid=c.get("uuid") or "",
                    is_member=False,
                    member_count=c.get("member_count") or 0,
                    message_count=c.get("message_count") or 0,
                    last_activity=c.get("last_interest_dt") or None,
                    avatar_url=avatar,
                ))

            await discuss_cache.set(
                company.id,
                "channels",
                partner_id,
                [r.model_dump(mode="json") for r in result],  # ✅ JSON SAFE
                ttl=120,
            )

            return result

            
        except Exception as e:
            logger.error(f"Error fetching channels: {e}")
            raise

    async def check_membership(self, company: models.Company, channel_id: int, partner_id: int) -> bool:
        """Hardened membership check used before any channel operation"""
        cache_key = f"member:{channel_id}:{partner_id}"
        is_member = await discuss_cache.get(company.id, "membership", cache_key)
        if is_member is not None:
            return bool(is_member)

        domain = [("channel_id", "=", channel_id), ("partner_id", "=", partner_id)]
        count = await odoo_client.execute_kw_async(
            company, "discuss.channel.member", "search_count", [domain]
        )
        
        member_exists = count > 0
        await discuss_cache.set(company.id, "membership", cache_key, int(member_exists), ttl=600)
        return member_exists

    async def get_messages(
        self, 
        company: models.Company, 
        channel_id: int, 
        partner_id: int,
        limit: int = 50,
        offset: int = 0
    ) -> List[MessageOut]:
        """Fetch message history with membership enforcement"""
        if not await self.check_membership(company, channel_id, partner_id):
            raise PermissionError("User is not a member of this channel")

        # Try cache for the first page
        if offset == 0 and limit == 50:
            cached = await discuss_cache.get(company.id, "messages", channel_id)
            if cached:
                return [MessageOut(**m) for m in cached]

        domain = [
            ("model", "=", "discuss.channel"),
            ("res_id", "=", channel_id),
            ("message_type", "=", "comment") # Filter for user messages
        ]
        fields = ["id", "body", "date", "author_id", "attachment_ids", "parent_id"]
        
        messages_raw = await odoo_client.execute_kw_async(
            company, "mail.message", "search_read",
            [domain], {"fields": fields, "limit": limit, "offset": offset, "order": "id desc"}
        )
        
        result = []
        for m in messages_raw:
            sender = m.get("author_id") # [id, name]
            result.append(MessageOut(
                id=m["id"],
                content=m.get("body") or "", 
                timestamp=m.get("date"),
                sender_id=sender[0] if sender else 0,
                sender_name=sender[1] if (sender and sender[1]) else "System",
                sequence=m["id"] 
            ))
            
        if offset == 0:
            await discuss_cache.set(company.id, "messages", channel_id, [r.dict() for r in result])
            
        return result

    async def get_inbox_messages(self, company: models.Company, partner_id: int, limit: int = 50, offset: int = 0) -> List[MessageOut]:
        """Fetch messages that need action (Inbox)"""
        if not partner_id: return []
        # In Odoo 17+, 'needaction' is often represented via mail.notification
        domain = [
            ("notification_ids.res_partner_id", "=", partner_id),
            ("notification_ids.is_read", "=", False),
            ("notification_ids.notification_type", "=", "inbox")
        ]
        return await self._fetch_special_messages(company, domain, limit, offset)

    async def get_starred_messages(self, company: models.Company, partner_id: int, limit: int = 50, offset: int = 0) -> List[MessageOut]:
        """Fetch favorited messages"""
        if not partner_id: return []
        # Stricter domain for starred messages
        domain = [
            ("starred_partner_ids", "in", [partner_id]),
            ("message_type", "=", "comment") # Exclude system notifications in Starred
        ]
        return await self._fetch_special_messages(company, domain, limit, offset)

    async def get_history_messages(self, company: models.Company, partner_id: int, limit: int = 50, offset: int = 0) -> List[MessageOut]:
        """Fetch all recent messages (History)"""
        if not partner_id: return []
        # Usually means all messages in channels the user is a member of
        # Odoo's 'history' is often everything except needaction, but we'll return recently received
        domain = [
            ("notification_ids.res_partner_id", "=", partner_id),
            ("notification_ids.is_read", "=", True)
        ]
        return await self._fetch_special_messages(company, domain, limit, offset)

    async def _fetch_special_messages(self, company: models.Company, domain: list, limit: int, offset: int) -> List[MessageOut]:
        """Helper to fetch messages from Odoo for virtual folders"""
        fields = ["id", "body", "date", "author_id", "res_id", "model"]
        messages_raw = await odoo_client.execute_kw_async(
            company, "mail.message", "search_read",
            [domain], {"fields": fields, "limit": limit, "offset": offset, "order": "id desc"}
        )
        
        result = []
        for m in messages_raw:
            sender = m.get("author_id")
            result.append(MessageOut(
                id=m["id"],
                content=m.get("body") or "",
                timestamp=m.get("date"),
                sender_id=sender[0] if sender else 0,
                sender_name=sender[1] if (sender and sender[1]) else "System",
                sequence=m["id"]
            ))
        return result

    async def post_message(
        self,
        company: models.Company,
        channel_id: int,
        partner_id: int,
        content: str,
        parent_id: Optional[int] = None,
        attachment_ids: List[int] = []
    ) -> MessageOut:
        """Post a new message with audit logging and cache bust"""
        if not await self.check_membership(company, channel_id, partner_id):
            raise PermissionError("User is not a member")

        # Basic HTML Sanitization placeholder
        # TODO: Implement robust sanitization
        safe_content = content.replace("<script", "&lt;script") 

        vals = {
            "body": safe_content,
            "model": "discuss.channel",
            "res_id": channel_id,
            "message_type": "comment",
            "author_id": partner_id,
            "parent_id": parent_id
        }
        
        if attachment_ids:
            vals["attachment_ids"] = [(6, 0, attachment_ids)]

        new_id = await odoo_client.execute_kw_async(
            company, "mail.message", "create", [vals]
        )
        
        # Read back for consistency
        msg_raw = await odoo_client.execute_kw_async(
            company, "mail.message", "read", [[new_id]]
        )
        
        m = msg_raw[0]
        sender = m.get("author_id")
        
        msg_out = MessageOut(
            id=m["id"],
            content=m.get("body") or "",
            timestamp=m.get("date"),
            sender_id=sender[0] if sender else 0,
            sender_name=sender[1] if (sender and sender[1]) else "Unknown",
            sequence=m["id"]
        )
        
        # Bust caches
        await discuss_cache.delete(company.id, "messages", channel_id)
        
        # Compliance Log
        logger.info(f"Message sent in channel {channel_id} by partner {partner_id}", extra={
             "action": "message_post",
             "channel_id": channel_id,
             "partner_id": partner_id,
             "message_id": new_id
        })
        
        return msg_out

    async def mark_as_read(self, company: models.Company, channel_id: int, partner_id: int, message_id: int):
        """Update last_seen_id on the member record"""
        # Find the member record ID
        member_ids = await odoo_client.execute_kw_async(
            company, "discuss.channel.member", "search",
            [[("channel_id", "=", channel_id), ("partner_id", "=", partner_id)]]
        )
        
        if not member_ids:
            return
            
        await odoo_client.execute_kw_async(
            company, "discuss.channel.member", "write",
            [member_ids, {"seen_message_id": message_id}]
        )
        
        # Bust unread cache
        await discuss_cache.delete(company.id, "unread", f"{channel_id}:{partner_id}")

discuss_service = DiscussService()
