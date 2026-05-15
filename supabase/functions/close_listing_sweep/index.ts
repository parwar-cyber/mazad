// close_listing_sweep — manual / external-scheduler trigger for the
// listing close sweep.
//
// The primary scheduler is pg_cron (see migration
// 20260514100001_phase3_bidding_engine.sql).  This Edge Function exists as
// a fallback for environments where pg_cron isn't available and for the
// admin "force-close stale listings" button (Phase 9 admin console).
//
// Auth model:
//   * Same request must include either a valid service-role JWT (admin
//     surface) or a `X-Admin-Trigger-Token` header matching the env var
//     ADMIN_TRIGGER_TOKEN (used by an external cron when service_role
//     credentials can't be plumbed).
//   * The function ALWAYS runs checkAppVersion(req) first.  Even though
//     the admin console is the typical caller, the auto-update skill
//     mandates the gate everywhere — including admin-only paths — so a
//     stale admin client can't accidentally drive a production sweep
//     against a newer DB.
//
// Output: { closed: N, listings: [{listing_id, new_status, winner_id, hammer}] }

import { createClient } from 'npm:@supabase/supabase-js@2';
import { checkAppVersion } from '../_shared/version_check.ts';
import { handlePreflight, jsonResponse } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  // App-version gate — runs BEFORE auth (auto-update skill).  A stale
  // client should always see the 426 first.
  const versionBlock = await checkAppVersion(req);
  if (versionBlock) return versionBlock;

  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'method_not_allowed' });
  }

  // Auth: service-role token OR ADMIN_TRIGGER_TOKEN header.
  const authHeader = req.headers.get('Authorization') ?? '';
  const adminToken = req.headers.get('X-Admin-Trigger-Token') ?? '';
  const expectedAdminToken = Deno.env.get('ADMIN_TRIGGER_TOKEN') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  const presentedJwt = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : '';

  const isServiceRole = presentedJwt.length > 0 && presentedJwt === serviceRoleKey;
  const isAdminToken =
    expectedAdminToken.length > 0 && adminToken === expectedAdminToken;

  if (!isServiceRole && !isAdminToken) {
    return jsonResponse(401, { error: 'unauthorized' });
  }

  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    serviceRoleKey,
  );

  let limit = 200;
  try {
    const body = await req.json().catch(() => ({}));
    if (typeof body?.limit === 'number' && body.limit > 0) {
      limit = Math.min(Math.floor(body.limit), 1000);
    }
  } catch {
    /* tolerant: no body required */
  }

  const { data, error } = await adminClient.rpc('close_listings_sweep', {
    p_limit: limit,
  });

  if (error) {
    console.log(JSON.stringify({
      event: 'close_listing_sweep.error',
      message: error.message,
      details: error.details ?? null,
    }));
    return jsonResponse(500, { error: 'sweep_failed', message: error.message });
  }

  const rows = Array.isArray(data) ? data : [];
  console.log(JSON.stringify({
    event: 'close_listing_sweep.ok',
    closed: rows.length,
  }));

  return jsonResponse(200, {
    closed: rows.length,
    listings: rows,
  });
});
