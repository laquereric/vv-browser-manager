# Conversations — Phase 2 (Maps to Existing vv Models)

API tier: **stable (v1)**
Controller: `llama_stack/conversations_controller.rb`, `llama_stack/conversations/items_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/conversations` | Create conversation |
| GET | `/v1/conversations/:conversation_id` | Retrieve conversation |
| POST | `/v1/conversations/:conversation_id` | Update conversation |
| DELETE | `/v1/conversations/:conversation_id` | Delete conversation |
| GET | `/v1/conversations/:conversation_id/items` | List items |
| GET | `/v1/conversations/:conversation_id/items/:item_id` | Retrieve item |

## vv Backend

- **Conversation → Session**: Direct mapping to host app `Session` table
- **Items → RES Events**: Events from RES stream `"session:{id}"`
- `session.messages_from_events` provides the event→message conversion

## Response Format (conversation)

```json
{
  "conversation_id": "session-{id}",
  "metadata": { "title": "Test Conversation" },
  "created_at": "2026-02-28T00:00:00Z"
}
```

## Response Format (items)

```json
{
  "object": "list",
  "data": [
    {
      "item_id": "event-{id}",
      "type": "message",
      "role": "user",
      "content": [{ "type": "text", "text": "Hello" }]
    }
  ],
  "has_more": false
}
```

## Mapping: vv → Llama Stack

| vv Field | Llama Stack Field |
|----------|------------------|
| `session.id` | `conversation_id` |
| `session.metadata` | `metadata` |
| `session.title` | `metadata.title` |
| RES events | `items` |

## Dependencies

- Host app `Session` table
- Rails Event Store (RES) streams

## Status

- [x] Controller (create, retrieve, update, delete)
- [x] Items controller (list, retrieve)
- [x] ResponseFormatter: Session → Conversation
- [x] ResponseFormatter: RES Event → Item
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
