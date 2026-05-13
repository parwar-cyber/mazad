// Shared Edge Function middleware.  Every function must call
// `checkAppVersion(req)` first and short-circuit on a returned Response.
//
// See .claude/skills/auto-update/SKILL.md.

import { createClient } from 'npm:@supabase/supabase-js@2';

export async function checkAppVersion(req: Request): Promise<Response | null> {
  const appVersion = req.headers.get('App-Version');
  const platform = req.headers.get('App-Platform');

  if (!appVersion || !platform) {
    return jsonResponse(400, { error: 'missing_version_headers' });
  }

  if (!isValidPlatform(platform)) {
    return jsonResponse(400, { error: 'invalid_platform' });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data, error } = await supabase
    .from('app_versions')
    .select('min_supported_version, current_version, release_notes_translations')
    .eq('platform', platform)
    .single();

  // Fail open — never block the user just because the version table is
  // momentarily unreadable.  Telemetry will surface the misconfiguration.
  if (error || !data) return null;

  if (compareSemver(appVersion, data.min_supported_version) < 0) {
    return jsonResponse(426, {
      error: 'upgrade_required',
      min_supported_version: data.min_supported_version,
      current_version: data.current_version,
      release_notes: data.release_notes_translations ?? {},
      store_url: storeUrlFor(platform),
    });
  }

  return null;
}

export function compareSemver(a: string, b: string): number {
  const pa = a.split('.').map((n) => Number.parseInt(n, 10) || 0);
  const pb = b.split('.').map((n) => Number.parseInt(n, 10) || 0);
  for (let i = 0; i < 3; i++) {
    if ((pa[i] ?? 0) !== (pb[i] ?? 0)) return (pa[i] ?? 0) - (pb[i] ?? 0);
  }
  return 0;
}

function isValidPlatform(p: string): p is 'ios' | 'android' | 'web' {
  return p === 'ios' || p === 'android' || p === 'web';
}

// Centralized store URLs.  Per the skill: do not scatter these strings.
export function storeUrlFor(platform: string): string {
  switch (platform) {
    case 'ios':
      return 'https://apps.apple.com/app/idXXXXXXXX'; // replace at App Store submission
    case 'android':
      return 'https://play.google.com/store/apps/details?id=com.mazad.app';
    case 'web':
      return 'https://app.mazad.iq';
    default:
      return 'https://mazad.iq';
  }
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
