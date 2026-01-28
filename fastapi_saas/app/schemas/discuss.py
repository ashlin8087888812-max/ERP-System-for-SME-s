from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from datetime import datetime

class MemberOut(BaseModel):
    id: int
    partner_id: int
    name: str
    avatar_url: Optional[str] = None
    is_self: bool = False
    last_seen_id: Optional[int] = None
    unread_count: int = 0

class ChannelOut(BaseModel):
    id: int
    name: str
    type: Literal["chat", "channel", "group"]
    description: Optional[str] = None
    uuid: str
    is_member: bool = False
    member_count: int = 0
    message_count: int = 0
    last_activity: Optional[datetime] = None
    avatar_url: Optional[str] = None
    members: List[MemberOut] = []

class AttachmentOut(BaseModel):
    id: int
    filename: str
    mime_type: str
    size: int
    parent_model: str
    parent_id: int

class MessageOut(BaseModel):
    id: int
    content: str
    timestamp: datetime
    sender_id: int
    sender_name: str
    sender_avatar: Optional[str] = None
    type: str = "comment"
    attachments: List[AttachmentOut] = []
    parent_id: Optional[int] = None
    is_starred: bool = False
    sequence: int # For WS ordering

class MessageCreate(BaseModel):
    content: str
    parent_id: Optional[int] = None
    attachment_ids: List[int] = []

class SeenUpdate(BaseModel):
    last_message_id: int
