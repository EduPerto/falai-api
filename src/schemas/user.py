"""
┌──────────────────────────────────────────────────────────────────────────────┐
│ @author: Eduardo Oliveira                                                     │
│ @file: user.py                                                               │
│ Developed by: Eduardo Oliveira                                                │
│ Creation date: May 13, 2025                                                  │
│ Contact: contato@evolution-api.com                                           │
├──────────────────────────────────────────────────────────────────────────────┤
│ @copyright © Falai 2025. All rights reserved.                        │
│ Licensed under the Apache License, Version 2.0                               │
│                                                                              │
│ You may not use this file except in compliance with the License.             │
│ You may obtain a copy of the License at                                      │
│                                                                              │
│    http://www.apache.org/licenses/LICENSE-2.0                                │
│                                                                              │
│ Unless required by applicable law or agreed to in writing, software          │
│ distributed under the License is distributed on an "AS IS" BASIS,            │
│ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     │
│ See the License for the specific language governing permissions and          │
│ limitations under the License.                                               │
├──────────────────────────────────────────────────────────────────────────────┤
│ @important                                                                   │
│ For any future changes to the code in this file, it is recommended to        │
│ include, together with the modification, the information of the developer    │
│ who changed it and the date of modification.                                 │
└──────────────────────────────────────────────────────────────────────────────┘
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
import uuid


class UserBase(BaseModel):
    email: EmailStr


class UserCreate(UserBase):
    password: str = Field(..., min_length=8, description="User password")
    name: str = Field(..., description="User's name")


class AdminUserCreate(UserBase):
    password: str
    name: str


class UserLogin(UserBase):
    password: str


class UserResponse(UserBase):
    id: uuid.UUID
    name: Optional[str] = None
    language: str = "en"
    is_active: bool
    is_admin: bool
    client_id: Optional[uuid.UUID] = None
    email_verified: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    user_id: Optional[uuid.UUID] = None
    sub: Optional[str] = None
    is_admin: bool
    client_id: Optional[uuid.UUID] = None
    exp: datetime


class PasswordReset(BaseModel):
    token: str
    new_password: str = Field(..., min_length=8, description="New password")


class ForgotPassword(BaseModel):
    email: EmailStr


class ChangePassword(BaseModel):
    current_password: str = Field(..., description="Current password for verification")
    new_password: str = Field(..., min_length=8, description="New password to set")


class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    name: Optional[str] = Field(None, min_length=1, description="User's name")
    language: Optional[str] = Field(None, pattern="^(en|pt-BR)$", description="User's preferred language")

    class Config:
        from_attributes = True


class AdminUserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, description="User's name")
    email: Optional[EmailStr] = None
    client_id: Optional[uuid.UUID] = None
    is_active: Optional[bool] = None

    class Config:
        from_attributes = True


class AdminResetPassword(BaseModel):
    new_password: str = Field(..., min_length=8, description="New password to set")


class MessageResponse(BaseModel):
    message: str
