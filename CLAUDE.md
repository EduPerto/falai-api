# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Evo AI is an open-source AI Agents Platform built as a full-stack monorepo with:
- **Backend**: FastAPI service at `/src` for agent execution and API
- **Frontend**: Next.js React application at `/frontend` for UI
- **Database**: PostgreSQL with Alembic migrations
- **Cache**: Redis for sessions and state management
- **Multi-Engine Support**: Google Agent Development Kit (ADK) primary, CrewAI in development

The platform enables creation and management of multiple AI agent types (LLM, A2A, Sequential, Parallel, Loop, Workflow, Task agents) with support for custom tools, MCP servers, and secure API key management.

## Common Development Commands

### Backend (Root Directory)

**Setup:**
```bash
make venv                    # Create Python virtual environment
make install-dev            # Install dependencies with dev tools
```

**Development:**
```bash
make run                     # Start backend server (hot reload)
make lint                    # Run flake8 code validation
make format                  # Format code with Black
```

**Database:**
```bash
make alembic-upgrade         # Apply all pending migrations
make alembic-revision message="description"  # Create new migration
make alembic-downgrade       # Revert one migration
make seed-all                # Run all database seeders
```

**Production:**
```bash
make run-prod                # Start with 4 workers
make docker-build            # Build Docker images
make docker-up               # Start Docker Compose services
make docker-seed             # Seed database in Docker
```

### Frontend (cd frontend)

```bash
pnpm install                 # Install dependencies
pnpm dev                     # Start development server (port 3000)
pnpm build                   # Production build
pnpm start                   # Run production build
pnpm lint                    # Run ESLint
```

## Backend Architecture

### Layered Service Architecture
- **Routes** (`/src/api`): REST endpoints with JWT authentication
- **Services** (`/src/services`): Business logic and domain operations
- **Models** (`/src/models`): SQLAlchemy ORM entities
- **Schemas** (`/src/schemas`): Pydantic validation models

### Key Service Structure
- **Agent Execution**: `agent_service.py` + `agent_runner.py` handle agent creation and execution
- **Authentication**: `auth_service.py` + JWT middleware for secure token management
- **Multi-Engine Support**: `services/adk/` (primary) and `services/crewai/` (in development)
- **A2A Protocol**: Enhanced A2A client in `utils/a2a_client.py` for agent interoperability
- **Observability**: OpenTelemetry integration with Langfuse support

### Important Configuration
- **Environment**: Settings in `/src/config/settings.py` - all config from `.env` file
- **Database**: Connection pooling configured in `config/database.py`
- **API Versioning**: All endpoints under `/api/v1/` prefix
- **AI Engine Selection**: Set via `AI_ENGINE` env var ("adk" or "crewai")

### Database Schema Patterns
- **Resource Ownership**: Agents/clients linked via `client_id` for multi-tenancy
- **Flexible Agent Types**: Single `agents` table with `agent_type` field for different agent classes
- **Sessions & Conversations**: Session-based chat history with message tracking
- **Encrypted Storage**: API keys stored encrypted using `ENCRYPTION_KEY` config

## Frontend Architecture

### Next.js App Router Structure
- **Pages** (`/app`): Route-based pages with server/client component separation
- **Components** (`/components`): Reusable UI components using shadcn/ui
- **Services** (`/services`): API calls via Axios to backend
- **Contexts** (`/contexts`): Global state management (auth, user, theme)
- **Hooks** (`/hooks`): Custom React hooks for shared logic
- **Types** (`/types`): TypeScript definitions for API responses

### Key Features
- **Authentication Flow**: Login/logout with JWT tokens stored securely
- **Agent Management**: Visual editor for agent configuration
- **Chat Interface**: Real-time chat with agents using session IDs
- **Theme Support**: Dark mode via `next-themes`
- **Visual Workflows**: ReactFlow/XyFlow for node-based agent workflows
- **Form Handling**: React Hook Form + Zod for validation

### Frontend Configuration
- **API URL**: `NEXT_PUBLIC_API_URL` env var (default: http://localhost:8000)
- **Runtime Env**: Configured via `next-runtime-env` for environment variables

## Important Code Patterns

### Service Dependency Injection
Services are instantiated in `src/services/service_providers.py` and injected into routes. Always retrieve services from the provider rather than instantiating directly.

### Agent Type System
Agent types are defined by `agent_type` field in database:
- `"llm"` - Language model agent
- `"a2a"` - Agent-to-Agent protocol
- `"sequential"` - Sequential sub-agent execution
- `"parallel"` - Concurrent sub-agent execution
- `"loop"` - Iterative sub-agent execution
- `"workflow"` - LangGraph-based workflow execution
- `"task"` - Task-specific execution

Different builders handle each type - check `services/agent_builder.py` or engine-specific builders.

### API Key Encryption
All sensitive API keys are encrypted before database storage using the `ENCRYPTION_KEY` from settings. Use encryption utilities in `utils/security.py` for encryption/decryption operations.

### MCP Server Integration
Model Context Protocol servers are managed via `mcp_server_routes.py` and `mcp_server_service.py`. Integration provides extensible tool support for agents.

### Authentication Flow
- JWT tokens expire based on `JWT_EXPIRATION_HOURS` setting
- Email verification tokens use a separate signing key
- Account lockout enforced after `MAX_LOGIN_ATTEMPTS` failures
- Resource access controlled via `client_id` in JWT payload

### A2A Protocol
- Uses enhanced A2A client for agent-to-agent communication
- Protocol state managed in Redis
- Client reference in `utils/a2a_client.py`

## Database Migrations

Use Alembic for schema changes:
```bash
make alembic-revision message="add user roles table"
# Edit migrations/versions/xxxx_*.py
make alembic-upgrade
```

Migration naming convention:
- Descriptive snake_case names
- Auto-generated revision hash
- Review generated code before applying

## Environment Configuration

### Critical Backend Variables
- `POSTGRES_CONNECTION_STRING` - Database connection
- `REDIS_HOST`, `REDIS_PORT` - Cache configuration
- `JWT_SECRET_KEY` - Token signing key
- `ENCRYPTION_KEY` - API key encryption
- `AI_ENGINE` - "adk" (default) or "crewai"
- `EMAIL_PROVIDER` - "sendgrid" or "smtp"
- `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY` - Observability

### Critical Frontend Variables
- `NEXT_PUBLIC_API_URL` - Backend API endpoint

See `.env.example` files for complete variable documentation.

## Code Standards

### Language & Naming
- All code, comments, documentation, and commits in **English**
- 4-space indentation
- Maximum 79 characters per line
- English-only user-facing content (emails, API responses)

### Commit Messages
Follow Conventional Commits format:
- `feat(scope): description` - New features
- `fix(scope): description` - Bug fixes
- `refactor(scope): description` - Code restructuring
- `docs: description` - Documentation changes
- Example: `feat(agents): add workflow agent support`

### Type Safety
- Backend: Use Pydantic schemas for all input validation, type hints for functions
- Frontend: Use TypeScript exclusively, avoid `any` type
- SQLAlchemy: Use explicit column types with proper constraints

### Error Handling
- Backend: Use HTTPException with appropriate status codes (201 for creation, 204 for deletion)
- Frontend: Implement proper loading states and error messages
- Always roll back database transactions on errors

### Testing
- Backend tests in `/tests` directory via pytest
- Run single test: `pytest tests/test_file.py::test_function`
- Frontend: Focus on critical business logic

## Frontend-Specific Notes

### Component Structure
- Complex multi-section components: Use folders with `index.tsx`
- Simple components: Single PascalCase file
- Avoid prop drilling beyond 2 levels - use Context

### API Service Pattern
Create service modules in `/frontend/services/`:
```typescript
export const fetchAgents = async () => {
  const response = await axios.get(`${API_URL}/agents`);
  return response.data;
};
```

### Styling
- Tailwind CSS for all styling
- shadcn/ui components as building blocks
- Consistent spacing and sizing conventions

## Special Considerations

### Multi-Tenancy
The platform is designed for multi-client isolation using `client_id`. Always verify resource ownership before allowing operations.

### Extensibility
- Tools: Created via `tool_routes.py` and managed by agents
- MCP Servers: Configured in UI and integrated with agents
- Agent Types: Add new types via engine-specific builders
- Email Templates: Use Jinja2 inheritance from `templates/emails/base_email.html`

### Performance
- Redis caching for frequently accessed data
- Connection pooling for database
- Frontend code splitting via dynamic imports
- Image optimization via Next.js Image component

### Security
- JWT with configurable expiration
- Email verification for registration
- Account lockout mechanism
- Bcrypt password hashing
- API key encryption at rest
- Resource-based access control via client_id
- Audit logging for admin actions

## Useful Endpoints

**Backend API documentation:**
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

**Frontend:**
- Development: `http://localhost:3000`
- Production: `http://localhost:3000` (after build)

## Debugging Tips

- Check backend logs: `make run` shows detailed output with timestamps
- Database issues: Use `make alembic-downgrade` to rollback, then investigate
- Frontend issues: Browser DevTools + check network tab for API calls
- Redis issues: Verify `REDIS_HOST` and `REDIS_PORT` in `.env`
- JWT issues: Check token expiration with `JWT_EXPIRATION_HOURS`

## Initial Setup Checklist

1. `make venv && make install-dev` - Backend environment
2. `cp .env.example .env` - Configure backend
3. `make alembic-upgrade && make seed-all` - Database setup
4. `cd frontend && pnpm install` - Frontend dependencies
5. `cp .env.example .env` (in frontend) - Configure frontend
6. `make run` - Start backend (terminal 1)
7. `cd frontend && pnpm dev` - Start frontend (terminal 2)
