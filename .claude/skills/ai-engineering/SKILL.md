---
name: ai-engineering
description: Guidelines for building AI-powered applications with LangChain v1, LangGraph, and LLM integration. Use when creating agents, chains, RAG pipelines, multi-agent systems, or any LLM-based application. Triggers on tasks involving langchain, langgraph, langsmith, agent creation, tool calling, middleware, or retrieval-augmented generation.
---

# AI Engineering

Build AI applications using LangChain v1+, LangGraph, and related frameworks.
Patterns verified against latest official documentation. Always verify with context7 before implementing.

## When to Apply

- Building AI agents, chains, or pipelines
- Integrating LLMs (OpenAI, Anthropic, Google, etc.)
- LangChain, LangGraph, LangSmith projects
- Multi-agent orchestration
- RAG (Retrieval-Augmented Generation)

## Critical: LangChain v1 Breaking Changes

### Agent Creation → `create_agent`

`create_agent` is the new standard. **Do NOT use** `create_react_agent`, `AgentExecutor`, or legacy chains.

```python
from langchain.agents import create_agent

agent = create_agent(
    model=model,
    tools=tools,
    system_prompt="You are a helpful assistant.",
    middleware=[],          # optional
    store=None,             # optional: memory store
    context_schema=None,    # optional: typed context
    checkpointer=None,      # optional: state persistence
)

result = await agent.ainvoke({"messages": [{"role": "user", "content": "Hello"}]})
```

### Middleware System (v1 Defining Feature)

Cross-cutting concerns via composable middleware. This replaces manual callback/hook patterns.

**Built-in:**
- `SummarizationMiddleware` - Compresses long conversations
- `HumanInTheLoopMiddleware` - Human approval for specific tools
- `PIIMiddleware` - Redacts personally identifiable information
- `FilesystemFileSearchMiddleware` - File search capabilities

```python
from langchain.agents import create_agent
from langchain.middleware import SummarizationMiddleware, HumanInTheLoopMiddleware

agent = create_agent(
    model=model,
    tools=tools,
    middleware=[
        SummarizationMiddleware(max_messages=20),
        HumanInTheLoopMiddleware(tools_requiring_approval=["execute_sql"]),
    ],
)
```

**Custom middleware:**
```python
from langchain.middleware import AgentMiddleware

class LoggingMiddleware(AgentMiddleware):
    async def wrap_model_call(self, model_call, messages, **kwargs):
        print(f"Sending {len(messages)} messages")
        response = await model_call(messages, **kwargs)
        return response
```

### Legacy Code → Deprecated

| Old (0.x) | New (v1+) |
|-----------|-----------|
| `create_react_agent` | `create_agent` |
| `AgentExecutor` | `create_agent` return value |
| `LLMChain`, `ConversationalChain` | LCEL or `create_agent` |
| Manual callbacks | Middleware system |
| `langchain.chains.*` | `langchain-classic` (if needed) |

### LCEL: Simple Pipelines Only

Use LCEL for RAG chains and data transformation. **Do NOT build agents with LCEL.**

```python
chain = (
    {"context": retriever, "question": RunnablePassthrough()}
    | prompt
    | model
    | StrOutputParser()
)
```

## LangGraph: Complex Workflows

Use when you need custom state management, conditional routing, or multi-agent orchestration.

**Simple case — `MessagesState`:**
```python
from langgraph.graph import StateGraph, START, END
from langgraph.prebuilt import MessagesState

graph = StateGraph(MessagesState)
graph.add_node("chatbot", chatbot_fn)
graph.add_edge(START, "chatbot")
graph.add_edge("chatbot", END)
app = graph.compile()
```

**Complex case — custom state:**
```python
from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    context: dict
    step_count: int
```

**Functional API (alternative):**
```python
from langgraph.func import entrypoint, task

@task
async def analyze(data: str) -> str:
    return await model.ainvoke(f"Analyze: {data}")

@entrypoint()
async def workflow(inputs: dict):
    return await analyze(inputs["data"])
```

## Decision Guide

| Need | Use |
|------|-----|
| Simple agent with tools | `create_agent` |
| Agent + cross-cutting concerns | `create_agent` + middleware |
| Simple chain (RAG, transform) | LCEL |
| Complex state / routing / multi-agent | LangGraph `StateGraph` |
| Lightweight workflow | LangGraph Functional API |

## Key Patterns

**Model init — always specify version:**
```python
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
model = ChatOpenAI(model="gpt-4o", temperature=0)
```

**Structured output:**
```python
class Result(BaseModel):
    title: str = Field(description="Result title")
    score: float = Field(ge=0, le=1)

structured = model.with_structured_output(Result)
```

**Streaming:**
```python
async for event in agent.astream_events(inputs, version="v2"):
    if event["event"] == "on_chat_model_stream":
        print(event["data"]["chunk"].content, end="")
```

**Memory persistence:**
```python
from langgraph.checkpoint.memory import MemorySaver
agent = create_agent(model=model, tools=tools, checkpointer=MemorySaver())
config = {"configurable": {"thread_id": "user-123"}}
```

## Anti-Patterns

- **Do NOT** use `create_react_agent` — deprecated in v1
- **Do NOT** use `AgentExecutor` — replaced by `create_agent`
- **Do NOT** use legacy chains (`LLMChain`, etc.) — use LCEL or `create_agent`
- **Do NOT** build agents with raw LCEL — use `create_agent` + middleware
- **Do NOT** hardcode API keys — use env vars or secret managers
- **Do NOT** skip error handling on LLM calls — handle rate limits, timeouts

## Project Structure

```
src/
  agents/           # create_agent definitions
  chains/           # LCEL pipelines
  graphs/           # LangGraph workflows
  tools/            # @tool definitions
  middleware/       # Custom AgentMiddleware
  prompts/          # Prompt templates
  models/           # Pydantic structured output
  retrievers/       # RAG configs
```

## Before Implementing

Always verify API signatures with context7 — LangChain ecosystem evolves rapidly.
See `resources/` for migration guides and advanced patterns.
