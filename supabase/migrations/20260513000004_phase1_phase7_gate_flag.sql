-- ─────────────────────────────────────────────────────────────────────────
-- Hard gate: Phase 7 escrow (real money) cannot launch until Phase 9's
-- admin KYC review queue exists.  See docs/decisions.md ADR-0008.
--
-- The flag is created at Phase 1 (now) so:
--   1. The contract is explicit and code can reference it from day one.
--   2. Phase 7 wiring will read `feature_flag('phase7_escrow_enabled')`
--      and refuse to operate until the flag is flipped.
--   3. Flipping the flag is a single conscious decision tied to Phase 9
--      review-queue readiness — not a silent code-deploy event.
-- ─────────────────────────────────────────────────────────────────────────

insert into feature_flags (name, enabled, description) values
  (
    'phase7_escrow_enabled',
    false,
    'Hard gate: Phase 7 real-money escrow. Flip ON only after Phase 9 admin KYC review queue is live (see ADR-0008).'
  )
on conflict (name) do nothing;
