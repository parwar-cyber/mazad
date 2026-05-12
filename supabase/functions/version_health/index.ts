// Diagnostic endpoint for the auto-update wiring.  Call from the client at
// boot to sanity-check the gate.  Returns 200 with the current version row
// if the client's version is allowed, or 426 (via checkAppVersion) if not.
//
// Phase 0 only ships this one function so we can verify the entire layer end
// to end before any business RPC is added.

import { checkAppVersion } from '../_shared/version_check.ts';

Deno.serve(async (req) => {
  const block = await checkAppVersion(req);
  if (block) return block;

  return new Response(
    JSON.stringify({ ok: true, ts: new Date().toISOString() }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
