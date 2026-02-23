---
name: python-backend
description: Guidelines for Python backend development with FastAPI, Django, WebSocket, and async patterns. Use when building REST APIs, WebSocket servers, async services, database integrations, or any Python web backend. Triggers on tasks involving fastapi, django, uvicorn, websocket, sqlalchemy, alembic, django channels, or async Python.
---

# Python Backend

Backend development with FastAPI, Django, and async Python.
Claude already knows these frameworks well — this skill focuses on conventions and guardrails.

## When to Apply

- FastAPI / Django projects
- REST API / WebSocket development
- Async Python services
- Database integration (SQLAlchemy, Django ORM)

## Framework Selection

| Need | Use |
|------|-----|
| High-performance async API | FastAPI |
| Full-featured web app + admin | Django |
| WebSocket (FastAPI) | `fastapi.WebSocket` |
| WebSocket (Django) | Django Channels (`AsyncWebsocketConsumer`) |
| Background tasks | Celery / `BackgroundTasks` / `asyncio.create_task` |

## FastAPI Conventions

- **Pydantic v2** is the default — do NOT use v1 patterns (`orm_mode` → `from_attributes=True`, `Config` class → `model_config` dict)
- Use `Annotated[T, Depends(...)]` for dependency injection
- Always define response models with Pydantic `BaseModel`
- Use `lifespan` context manager for startup/shutdown (not `@app.on_event`)
- Group routes with `APIRouter`, prefix with `/api/v1/`

```python
# Pydantic v2 + Annotated DI pattern
class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str

DbSession = Annotated[AsyncSession, Depends(get_db)]
```

## Django Conventions

- Use async views where I/O-bound (`async def view(request)`)
- Use `sync_to_async` for ORM calls in async contexts
- Always define serializers for API responses (DRF)
- Use `select_related` / `prefetch_related` to avoid N+1

## Django Channels (WebSocket)

Django에서 WebSocket은 Django Channels를 사용.

```python
# consumers.py
from channels.generic.websocket import AsyncWebsocketConsumer
import json

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_name = self.scope["url_route"]["kwargs"]["room_name"]
        self.room_group_name = f"chat_{self.room_name}"
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        await self.channel_layer.group_send(
            self.room_group_name,
            {"type": "chat.message", "message": data["message"]},
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({"message": event["message"]}))
```

```python
# routing.py
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r"ws/chat/(?P<room_name>\w+)/$", consumers.ChatConsumer.as_asgi()),
]
```

```python
# asgi.py
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(URLRouter(websocket_urlpatterns)),
})
```

**필수 설정:**
- `ASGI_APPLICATION` in settings.py
- Channel layer: `channels_redis` (production) or `InMemoryChannelLayer` (dev)
- ASGI server: `daphne` or `uvicorn`

## Async Patterns

- Prefer `async/await` for I/O-bound operations
- Use `asyncio.gather` for concurrent independent calls
- Never block the event loop — use `run_in_executor` for sync I/O
- Use `httpx.AsyncClient` (not `requests`) for HTTP calls
- Connection pools: `asyncpg` for PostgreSQL, `aioredis` for Redis

## WebSocket Common Rules (Both Frameworks)

- Always implement heartbeat/ping-pong
- Handle disconnection gracefully with try/except
- Use connection managers for broadcast patterns
- Validate incoming messages with Pydantic
- Implement reconnection logic on client side

## Database

- SQLAlchemy: use async engine + `AsyncSession`
- Alembic for migrations — always review before applying
- Use transactions explicitly for multi-step operations
- Index frequently queried columns

## Project Structure

```
src/
  api/              # Route handlers
  core/             # Config, security, dependencies
  models/           # SQLAlchemy / Django models
  schemas/          # Pydantic request/response models
  services/         # Business logic
  repositories/     # Data access layer
  middleware/       # Custom middleware
  consumers/        # WebSocket consumers (Django Channels)
  tasks/            # Background tasks
tests/
  api/
  services/
```

## Project Setup

When starting a new Python project, always install dev tools:

```bash
uv add --dev ruff mypy pytest
```

These are required for the auto quality-check hook (PostToolUse) to work.

## Anti-Patterns

- **Do NOT** use `requests` in async code — use `httpx.AsyncClient`
- **Do NOT** use `@app.on_event("startup")` — use `lifespan`
- **Do NOT** use Pydantic v1 `orm_mode` — use `from_attributes=True`
- **Do NOT** use bare `except` — catch specific exceptions
- **Do NOT** store secrets in code — use env vars
- **Do NOT** use `InMemoryChannelLayer` in production — use Redis

## Before Implementing

Verify latest API with context7 for major version changes.
