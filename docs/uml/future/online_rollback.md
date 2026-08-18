# Future — online rollback / store

Not implemented as a shipping matchmaker. Design references: `scripts/net/rollback_session_gd.gd`, `packages/rollback`.

```mermaid
flowchart LR
  P1[Player 1] --> NET[Rollback session]
  P2[Player 2] --> NET
  NET --> SM[FighterStateMachine]
```

Do not claim this path is live. Play Store AAB + release keystore remain owner-only.
