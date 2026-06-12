---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
<!-- Vendored from ECC 2.0.0-rc.1 rules/python/*.md -->

# Python Coding Style

## PEP 8 and Formatting

- Follow PEP 8 conventions for all code.
- Use **ruff** for both linting and formatting (`ruff check` + `ruff format`) — one tool replaces flake8/pylint/black/isort.

## Type Hints

Add type annotations to all function signatures (parameters and return types). Use `from __future__ import annotations` for forward references.

```python
def create_user(name: str, email: str) -> User:
    ...
```

## Immutability

Prefer immutable data structures. Use frozen dataclasses or NamedTuples for value objects:

```python
from dataclasses import dataclass
from typing import NamedTuple

@dataclass(frozen=True)
class User:
    name: str
    email: str

class Point(NamedTuple):
    x: float
    y: float
```

## Validation at Boundaries

Use Pydantic for schema-based validation at system boundaries (API request bodies, config, external data):

```python
from pydantic import BaseModel, EmailStr

class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr
    age: int | None = None
```

## Secret Management

Load secrets from environment variables, never hardcode them. Fail fast if required secrets are absent:

```python
import os
api_key = os.environ["OPENAI_API_KEY"]  # raises KeyError if missing
```

## Testing Conventions

- Use **pytest** as the testing framework; categorize with `pytest.mark` (`unit`, `integration`, `e2e`).
- Coverage targets, AAA structure, and test naming: follow the `tdd-workflow` skill.

## Duck Typing via Protocol

Use `typing.Protocol` for repository and service interfaces instead of abstract base classes:

```python
from typing import Protocol

class UserRepository(Protocol):
    def find_by_id(self, id: str) -> dict | None: ...
    def save(self, entity: dict) -> dict: ...
```

## Security

- Run **bandit** for static security analysis: `bandit -r src/`
- Never hardcode API keys, passwords, or tokens in source files.
