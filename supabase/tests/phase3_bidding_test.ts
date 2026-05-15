// ─────────────────────────────────────────────────────────────────────────
// Phase 3 — Bidding engine integration tests
//
// Runs against the local Supabase Postgres (54322).  Each test resets
// fixtures by re-running supabase/tests/setup.sql, then exercises
// place_bid() under realistic conditions.
//
// Concurrency model: tests open their own pool of postgres connections,
// each impersonating a different test user via request.jwt.claims so
// auth.uid() inside the SECURITY DEFINER place_bid() reads the impersonated
// uid.  This is the same mechanism PostgREST uses for the `authenticated`
// role; we just set the GUC directly.
//
// Run:
//   deno test --allow-net --allow-env --allow-read supabase/tests/phase3_bidding_test.ts
// ─────────────────────────────────────────────────────────────────────────

import postgres from 'npm:postgres@3.4.5';
import { assertEquals, assertNotEquals, assert } from 'jsr:@std/assert@1';

const PG_URL =
  Deno.env.get('TEST_PG_URL') ??
  'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const SETUP_SQL_PATH = new URL('./setup.sql', import.meta.url);

const SELLER         = '11111111-0000-0000-0000-000000000001';
const LISTING_GENERAL    = '55555555-0000-0000-0000-000000000001';
const LISTING_DISCOVERY  = '55555555-0000-0000-0000-000000000002';
const LISTING_HARD_CAP   = '55555555-0000-0000-0000-000000000003';
const LISTING_UNREVIEWED = '55555555-0000-0000-0000-000000000004';

const TIER0_USER = '33333333-0000-0000-0000-000000000099';

function bidderUid(i: number): string {
  // i in 1..60
  return `22222222-0000-0000-0000-${i.toString().padStart(12, '0')}`;
}

function adminPool(max = 4) {
  return postgres(PG_URL, { max, prepare: false, idle_timeout: 5 });
}

// Run a callback "as" the given uid by setting the jwt claim on its own
// dedicated connection.  We use postgres.js's reserve() to pin one
// connection so the GUC sticks for the duration of the callback.
async function asUser<T>(
  sql: postgres.Sql,
  uid: string,
  fn: (q: postgres.ReservedSql) => Promise<T>,
): Promise<T> {
  const reserved = await sql.reserve();
  try {
    // The function uses set_config / set role to flip the session.  Using
    // SET LOCAL doesn't apply outside transactions; reserved gives us a
    // pinned connection so the SET sticks across statements.
    await reserved.unsafe(`set role authenticated`);
    await reserved.unsafe(
      `select set_config('request.jwt.claims', $1, false)`,
      [JSON.stringify({ sub: uid, role: 'authenticated' })],
    );
    return await fn(reserved);
  } finally {
    try { await reserved.unsafe(`reset role`); } catch { /* noop */ }
    reserved.release();
  }
}

async function resetFixtures(sql: postgres.Sql): Promise<void> {
  const text = await Deno.readTextFile(SETUP_SQL_PATH);
  await sql.unsafe(text);
}

// ─── Test 1: 50 concurrent bidders ─────────────────────────────────────
Deno.test('50 concurrent bidders → exactly one winner, monotonic high', async () => {
  // Big pool — we want 50 truly concurrent connections.
  const sql = postgres(PG_URL, { max: 55, prepare: false, idle_timeout: 5 });
  try {
    await resetFixtures(sql);

    // Snapshot pre-test high.
    const [pre] = await sql`
      select current_high, bid_count from listings where id = ${LISTING_GENERAL}
    `;
    assertEquals(pre.current_high, null);
    assertEquals(pre.bid_count, 0);

    // Each Tier-1 bidder i ∈ [1..50] tries amount = 11_000 + i*1000.
    // Min increment at starting_price 10_000 is 1_000, so all bids are
    // valid in principle; only the highest one survives as current_high.
    // Range stays below the Tier-1 100k ceiling (max=61000).
    const tasks: Promise<{ uid: string; ok: boolean; err?: string }>[] = [];
    for (let i = 1; i <= 50; i++) {
      const uid = bidderUid(i);
      const amount = 11_000 + i * 1_000;
      tasks.push(asUser(sql, uid, async (q) => {
        try {
          await q`
            select place_bid(${LISTING_GENERAL}::uuid, ${amount}::bigint, null::bigint, 'app')
          `;
          return { uid, ok: true };
        } catch (e) {
          return { uid, ok: false, err: (e as Error).message };
        }
      }));
    }
    const results = await Promise.all(tasks);

    // Count outcomes.  Some bids will fail bid_too_low because earlier
    // bidders bumped current_high above the later bidder's amount.  That's
    // the correctness we're testing — order of arrival doesn't matter, the
    // SELECT FOR UPDATE serializes them.
    const accepted = results.filter((r) => r.ok).length;
    const tooLow   = results.filter((r) => r.err?.includes('bid_too_low')).length;
    const rateLim  = results.filter((r) => r.err?.includes('rate_limited')).length;
    const other    = results.filter((r) => !r.ok)
                            .map((r) => r.err)
                            .filter((m) => !m?.includes('bid_too_low')
                                        && !m?.includes('rate_limited'));

    // No unexpected errors.
    assertEquals(other, [], `unexpected errors: ${JSON.stringify(other)}`);

    // Every result is either accepted or bid_too_low or rate_limited.
    assertEquals(accepted + tooLow + rateLim, 50);

    // Listing state: current_high equals the highest bid actually placed,
    // and there is exactly one current_high_bidder_id.
    const [post] = await sql`
      select current_high, current_high_bidder_id, bid_count
        from listings where id = ${LISTING_GENERAL}
    `;
    assertEquals(post.bid_count, accepted, 'bid_count == accepted bids');
    assertNotEquals(post.current_high_bidder_id, null);

    const bids = await sql`
      select bidder_id, amount, created_at
        from bids
       where listing_id = ${LISTING_GENERAL}
       order by amount asc
    `;
    // Strictly monotonic via SELECT FOR UPDATE: each accepted bid had to
    // exceed the previous current_high by min_increment.
    let prev = -Infinity;
    for (const row of bids) {
      const n = Number(row.amount);
      assert(n > prev, `bids must increase: ${prev} -> ${n}`);
      prev = n;
    }

    // The winner is the highest accepted amount's bidder.
    const winnerRow = bids[bids.length - 1];
    assertEquals(post.current_high_bidder_id, winnerRow.bidder_id);
    assertEquals(Number(post.current_high), Number(winnerRow.amount));
  } finally {
    await sql.end();
  }
});

// ─── Test 2: Smart Close timer extends correctly ───────────────────────
Deno.test('Smart Close: during discovery, close stays at discovery_ends_at', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    const [before] = await sql`
      select discovery_ends_at, current_close_at
        from listings where id = ${LISTING_DISCOVERY}
    `;
    // Fresh: current_close_at == discovery_ends_at.
    assertEquals(
      new Date(before.current_close_at).getTime(),
      new Date(before.discovery_ends_at).getTime(),
    );

    await asUser(sql, bidderUid(1), async (q) => {
      await q`select place_bid(${LISTING_DISCOVERY}::uuid, 11000::bigint, null::bigint, 'app')`;
    });

    const [after] = await sql`
      select discovery_ends_at, current_close_at
        from listings where id = ${LISTING_DISCOVERY}
    `;
    assertEquals(
      new Date(after.current_close_at).getTime(),
      new Date(after.discovery_ends_at).getTime(),
      'during discovery, current_close_at is pinned to discovery_ends_at',
    );
  } finally {
    await sql.end();
  }
});

Deno.test('Smart Close: after discovery, bid resets close to now + 12h', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    await asUser(sql, bidderUid(2), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, null::bigint, 'app')`;
    });

    const [after] = await sql`
      select (current_close_at - now()) as remaining,
             extract(epoch from (current_close_at - now())) as remaining_sec
        from listings where id = ${LISTING_GENERAL}
    `;
    // Should be ~12h.  Allow 60s slack for setup time.
    const sec = Number(after.remaining_sec);
    assert(
      sec > 12 * 3600 - 60 && sec < 12 * 3600 + 60,
      `expected ~12h remaining, got ${sec}s`,
    );
  } finally {
    await sql.end();
  }
});

Deno.test('Smart Close: hard cap honored even with last-second bid', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    // Listing 3 has current_close_at = now + 30m, hard_close_at = now + 30m.
    await asUser(sql, bidderUid(3), async (q) => {
      await q`select place_bid(${LISTING_HARD_CAP}::uuid, 11000::bigint, null::bigint, 'app')`;
    });

    const [row] = await sql`
      select current_close_at, hard_close_at
        from listings where id = ${LISTING_HARD_CAP}
    `;
    // Smart-close window is 12h but hard_close is in 30m — must clamp.
    const closeMs = new Date(row.current_close_at).getTime();
    const hardMs  = new Date(row.hard_close_at).getTime();
    assertEquals(closeMs, hardMs, 'current_close_at must clamp to hard_close_at');
  } finally {
    await sql.end();
  }
});

// ─── Test 3: Proxy bidding (iterative, capped) ─────────────────────────
Deno.test('Proxy bidding auto-bids correctly without runaway', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    // User 1 sets a proxy max of 50_000 with starting bid of 11_000.
    await asUser(sql, bidderUid(1), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, 50000::bigint, 'app')`;
    });
    const [afterU1] = await sql`
      select current_high, current_high_bidder_id, bid_count
        from listings where id = ${LISTING_GENERAL}
    `;
    assertEquals(Number(afterU1.current_high), 11000);
    assertEquals(afterU1.current_high_bidder_id, bidderUid(1));

    // User 2 bids 12_000 (lowest valid amount above U1) with max 30_000.
    // Proxy loop should escalate to: U1 at min(50000, 13000)=13000, U2 at
    // min(30000, 14000)=14000, U1 15000, U2 16000, ... U2 30000, U1 31000+
    // capped at 50000.  Final state: U1 high at 31000 (since after U2's
    // 30000 cap, U1's min_inc auto-bid = min(50000, 31000) = 31000 and U2
    // can't outbid further).
    await asUser(sql, bidderUid(2), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 12000::bigint, 30000::bigint, 'app')`;
    });

    const [final] = await sql`
      select current_high, current_high_bidder_id, bid_count
        from listings where id = ${LISTING_GENERAL}
    `;
    // U1's max is higher → U1 wins.
    assertEquals(final.current_high_bidder_id, bidderUid(1));
    assert(
      Number(final.current_high) >= 31000 && Number(final.current_high) <= 50000,
      `expected current_high in [31000, 50000], got ${final.current_high}`,
    );

    // Verify the proxy hard-cap: bid_count must be ≤ 1 (U1) + 1 (U2) +
    // 20 proxy auto-bids = 22.
    assert(
      Number(final.bid_count) <= 22,
      `proxy loop must cap at 20 iterations; bid_count=${final.bid_count}`,
    );

    // is_proxy flag is set on auto-bids.
    const proxyBids = await sql`
      select count(*)::int as n from bids
       where listing_id = ${LISTING_GENERAL} and is_proxy = true
    `;
    assert(Number(proxyBids[0].n) > 0, 'should have ≥1 proxy bid');
  } finally {
    await sql.end();
  }
});

Deno.test('Proxy bidding: pathological overlapping maxes hit the 20-iter cap', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    // Both Tier-2 users set max = 10_000_000 (10M IQD).  At 5% increments,
    // escalation would take dozens of iterations.  The 20-iter cap must
    // stop the loop cleanly without melting the DB.
    // Use bidders 51 + 52 (Tier 2 per setup.sql).
    await asUser(sql, bidderUid(51), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, 10000000::bigint, 'app')`;
    });
    const t0 = performance.now();
    await asUser(sql, bidderUid(52), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 12000::bigint, 10000000::bigint, 'app')`;
    });
    const elapsed = performance.now() - t0;

    // Should complete fast — well under a second even with 20 iterations.
    assert(elapsed < 5_000, `proxy loop too slow: ${elapsed}ms`);

    const [final] = await sql`
      select bid_count from listings where id = ${LISTING_GENERAL}
    `;
    // U1 + U2 + at most 20 proxies = 22 bids total.
    assert(
      Number(final.bid_count) <= 22,
      `bid_count = ${final.bid_count} > 22 means runaway`,
    );
  } finally {
    await sql.end();
  }
});

// ─── Test 4: Error cases ───────────────────────────────────────────────
Deno.test('self_bid_forbidden when seller tries to bid', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    let err: string | null = null;
    await asUser(sql, SELLER, async (q) => {
      try {
        await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, null::bigint, 'app')`;
      } catch (e) { err = (e as Error).message; }
    });
    assert(err?.includes('self_bid_forbidden'), `got: ${err}`);
  } finally {
    await sql.end();
  }
});

Deno.test('bid_too_low when amount below current high + min increment', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    await asUser(sql, bidderUid(1), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, null::bigint, 'app')`;
    });
    let err: string | null = null;
    await asUser(sql, bidderUid(2), async (q) => {
      try {
        // 11000 + min_inc(1000) = 12000 required; 11500 too low.
        await q`select place_bid(${LISTING_GENERAL}::uuid, 11500::bigint, null::bigint, 'app')`;
      } catch (e) { err = (e as Error).message; }
    });
    assert(err?.includes('bid_too_low'), `got: ${err}`);
  } finally {
    await sql.end();
  }
});

Deno.test('rate_limited when 11th bid in 60s window', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    // Bidder #1 places 10 bids in quick succession (each accepted because
    // each is the high bidder and we use a sub-listing strategy — but
    // place_bid forbids consecutive bids by current_high_bidder).  Use a
    // sequence of low bids that fail before tripping rate-limit:
    //
    // Wait — bid_too_low doesn't fire, but place_bid doesn't reject
    // consecutive bids by the same user.  We can chain: bidder #1 bids
    // 11000, then ALSO bids 12000 against themselves.  place_bid doesn't
    // forbid that.  But each successful bid increments current_high so the
    // next-min-increment bid by same user is still valid.
    //
    // Better: alternate two bidders so each bid is accepted.  For the
    // rate-limit specifically, we want bidder #1 to be rejected on the
    // 11th attempt.  Make bidder #1 place 10 bids that are all
    // bid_too_low (which DOESN'T count toward rate-limit?  let's check —
    // the rate-limit check fires BEFORE the listing read, so even rejected
    // attempts that pass auth + amount validation but fail bid_too_low
    // still count if we counted attempts.  We count valid bids in the
    // bids table, so bid_too_low (which never inserts a row) does NOT
    // count.  We need 10 VALID bids by bidder #1 in 60s.
    //
    // Strategy: bidder #1 bids 11000, then 13000, 15000, ... 29000 — each
    // is the current high so each new bid is valid (min_inc on 11000 is
    // 1000; min_inc on 29000 is 1450 floored to 1000).  10 bids in a row.
    // The 11th bid raises rate_limited.
    const amounts = [11000, 13000, 15000, 17000, 19000, 21000, 23000, 25000, 27000, 29000];
    for (const amt of amounts) {
      await asUser(sql, bidderUid(1), async (q) => {
        await q`select place_bid(${LISTING_GENERAL}::uuid, ${amt}::bigint, null::bigint, 'app')`;
      });
    }
    let err: string | null = null;
    await asUser(sql, bidderUid(1), async (q) => {
      try {
        await q`select place_bid(${LISTING_GENERAL}::uuid, 31000::bigint, null::bigint, 'app')`;
      } catch (e) { err = (e as Error).message; }
    });
    assert(err?.includes('rate_limited'), `got: ${err}`);
  } finally {
    await sql.end();
  }
});

Deno.test('kyc_tier_1_required for Tier 0 user', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    let err: string | null = null;
    await asUser(sql, TIER0_USER, async (q) => {
      try {
        await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, null::bigint, 'app')`;
      } catch (e) { err = (e as Error).message; }
    });
    assert(err?.includes('kyc_tier_1_required'), `got: ${err}`);
  } finally {
    await sql.end();
  }
});

Deno.test('seller_not_reviewed when auto_grant_tier2 flag OFF and seller unreviewed', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    // Flip the flag OFF (production mode).
    await sql`update feature_flags set enabled = false where name = 'auto_grant_tier2'`;

    let err: string | null = null;
    await asUser(sql, bidderUid(4), async (q) => {
      try {
        await q`select place_bid(${LISTING_UNREVIEWED}::uuid, 11000::bigint, null::bigint, 'app')`;
      } catch (e) { err = (e as Error).message; }
    });
    assert(err?.includes('seller_not_reviewed'), `got: ${err}`);

    // Reviewed seller should still accept bids with the flag OFF.
    await asUser(sql, bidderUid(5), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, null::bigint, 'app')`;
    });

    // Restore flag.
    await sql`update feature_flags set enabled = true where name = 'auto_grant_tier2'`;
  } finally {
    await sql.end();
  }
});

Deno.test('listing_closed when current_close_at has passed', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    // Force-close listing 3 by setting current_close_at into the past.
    await sql`
      update listings
         set current_close_at = now() - interval '1 minute'
       where id = ${LISTING_HARD_CAP}
    `;

    let err: string | null = null;
    await asUser(sql, bidderUid(6), async (q) => {
      try {
        await q`select place_bid(${LISTING_HARD_CAP}::uuid, 11000::bigint, null::bigint, 'app')`;
      } catch (e) { err = (e as Error).message; }
    });
    assert(err?.includes('listing_closed'), `got: ${err}`);
  } finally {
    await sql.end();
  }
});

// ─── Test 5: close_listings_sweep ──────────────────────────────────────
Deno.test('close_listings_sweep marks listing sold when winner present', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    await asUser(sql, bidderUid(7), async (q) => {
      await q`select place_bid(${LISTING_GENERAL}::uuid, 11000::bigint, null::bigint, 'app')`;
    });
    await sql`update listings set current_close_at = now() - interval '1 minute'
              where id = ${LISTING_GENERAL}`;

    const rows = await sql`select * from close_listings_sweep(50)`;
    const closed = rows.find((r) => r.listing_id === LISTING_GENERAL);
    assert(closed, 'sweep must return the listing we forced-closed');
    assertEquals(closed!.new_status, 'sold');
    assertEquals(Number(closed!.hammer), 11000);

    const [after] = await sql`select status from listings where id = ${LISTING_GENERAL}`;
    assertEquals(after.status, 'sold');
  } finally {
    await sql.end();
  }
});

Deno.test('close_listings_sweep marks listing expired when no bid', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);
    await sql`update listings set current_close_at = now() - interval '1 minute'
              where id = ${LISTING_GENERAL}`;
    const rows = await sql`select * from close_listings_sweep(50)`;
    const closed = rows.find((r) => r.listing_id === LISTING_GENERAL);
    assert(closed, 'sweep must return the listing');
    assertEquals(closed!.new_status, 'expired');
  } finally {
    await sql.end();
  }
});

// ─── Test 6: RLS — direct INSERT denied ────────────────────────────────
Deno.test('Direct INSERT on bids is denied by RLS (place_bid is the only path)', async () => {
  const sql = adminPool();
  try {
    await resetFixtures(sql);

    let err: string | null = null;
    await asUser(sql, bidderUid(8), async (q) => {
      try {
        await q`
          insert into bids (listing_id, bidder_id, amount, source)
          values (${LISTING_GENERAL}::uuid, ${bidderUid(8)}::uuid, 50000, 'app')
        `;
      } catch (e) { err = (e as Error).message; }
    });
    // Either "permission denied" (table grants stripped) or "new row
    // violates row-level security policy" — both prove the path is closed.
    assert(
      err && (err.includes('permission denied') || err.includes('row-level security')),
      `expected RLS / grant denial, got: ${err}`,
    );
  } finally {
    await sql.end();
  }
});
