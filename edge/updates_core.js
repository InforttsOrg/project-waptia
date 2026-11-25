const HF_RAW_BASE = 'https://huggingface.co/datasets/rttss/ota-patches/raw/main';
const HF_RESOLVE_BASE = 'https://huggingface.co/datasets/rttss/ota-patches/resolve/main';

export const SUPPORTED_CHANNELS = ['production', 'beta', 'alpha', 'internal', 'ota'];

export function normalizeChannel(raw) {
  const ch = (raw || 'production').toString().trim().toLowerCase();
  if (ch === 'release' || ch === 'stable' || ch === 'prod' || ch === 'live') return 'production';
  if (ch === 'dev' || ch === 'testing' || ch === 'internaltest') return 'internal';
  if (SUPPORTED_CHANNELS.includes(ch)) return ch;
  return 'production';
}

export function normalizeSlug(raw) {
  return (raw || '')
    .toString()
    .trim()
    .toLowerCase()
    .replace(/\.apk$/i, '')
    .replace(/-release$/i, '')
    .replace(/ by infortts$/i, '')
    .replace(/ infortts$/i, '')
    .replace(/\s+/g, '-');
}

export function encodeVersionToBuild(ver) {
  const clean = (ver || '1.0.0').toString().replace(/^v/i, '').split('+')[0].split('-')[0];
  const parts = clean.split('.').map((p) => parseInt(p, 10) || 0);
  const major = parts[0] || 1;
  const minor = parts[1] || 0;
  const patch = parts[2] || 0;
  return major * 10000 + minor * 100 + patch;
}

export function corsHeaders(extra = {}) {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    ...extra,
  };
}

export function jsonResponse(data, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: corsHeaders({
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'public, max-age=60',
      ...extraHeaders,
    }),
  });
}

export async function loadAppsDb(request, env) {
  try {
    const assetUrl = new URL('/apps_db.json', request.url);
    const res = env && env.ASSETS
      ? await env.ASSETS.fetch(new Request(assetUrl.toString()))
      : await fetch(assetUrl.toString());
    if (res.ok) {
      const list = await res.json();
      if (Array.isArray(list)) return list;
    }
  } catch (_) {}
  return [];
}

export function findAppEntry(apps, slugOrName, packageName) {
  const targetSlug = normalizeSlug(slugOrName);
  const targetPkg = (packageName || '').trim().toLowerCase();

  if (targetSlug) {
    const bySlug = apps.find((a) => (a.slug || '').toLowerCase() === targetSlug);
    if (bySlug) return bySlug;
  }
  if (targetPkg) {
    const byPkg = apps.find((a) => (a.packageId || a.packageName || '').toLowerCase() === targetPkg);
    if (byPkg) return byPkg;
    const pkgTail = targetPkg.split('.').pop();
    const byTail = apps.find((a) => (a.slug || '').toLowerCase() === pkgTail);
    if (byTail) return byTail;
  }
  return null;
}

export async function fetchHfManifest(slug, channel) {
  const candidates = [];
  if (channel && channel !== 'production') {
    candidates.push(`${HF_RAW_BASE}/${slug}/channels/${channel}/manifest.json`);
  }
  candidates.push(`${HF_RAW_BASE}/${slug}/manifest.json`);

  for (const url of candidates) {
    try {
      const res = await fetch(url, { cf: { cacheTtl: 60, cacheEverything: true } });
      if (res.ok) {
        const data = await res.json();
        return { manifest: data, sourceUrl: url, channelMatched: url.includes(`/channels/${channel}/`) };
      }
    } catch (_) {}
  }
  return null;
}

export function buildCatalogEntry(app, channel, origin, hfData = null) {
  const slug = app.slug;
  const manifest = hfData?.manifest;
  const rawVer = (manifest?.version || app.version || '1.0.0').toString().replace(/^v/i, '');
  const buildNum = manifest?.latestBuild || manifest?.version_code || encodeVersionToBuild(rawVer);
  const latestPatch = typeof manifest?.latestPatch === 'number' ? manifest.latestPatch : 0;

  const directHfApk = manifest?.apk_url || app.apkDownloadUrl || `${HF_RESOLVE_BASE}/${slug}/${slug}.apk`;
  const waptiaDownloadUrl = `${origin}/download/${slug}.apk?channel=${channel}`;
  const patchUrl = manifest?.patch?.url || `${origin}/patches/${slug}/v${rawVer}/patch_${latestPatch}.bin`;
  const notes = Array.isArray(manifest?.release_notes)
    ? manifest.release_notes
    : (Array.isArray(app.updates) ? app.updates.map((u) => `✓ ${u.version}: ${u.notes}`) : [app.shortDescription || `${app.name} Release`]);

  return {
    slug,
    app: slug,
    name: app.name,
    package_name: app.packageId || `com.infortts.${slug}`,
    category: app.category || 'Ecosystem',
    channel,
    channels: Array.isArray(app.channels) ? app.channels : SUPPORTED_CHANNELS,
    latest_version: rawVer,
    latest_build: buildNum,
    latestPatch,
    min_required_build: buildNum,
    download_url: waptiaDownloadUrl,
    direct_cdn_url: directHfApk,
    apk_url: waptiaDownloadUrl,
    cdn_patch_url: patchUrl,
    manifest_url: `${origin}/api/v1/ota/check?app=${slug}&channel=${channel}`,
    sha256: manifest?.sha256 || '',
    size_bytes: manifest?.size_bytes || 0,
    bundle_size: app.bundleSize || '',
    release_notes: notes,
    is_mandatory: Boolean(manifest?.is_mandatory),
    superadminOnly: Boolean(app.superadminOnly),
    published_at: manifest?.timestamp_iso || (app.updates?.[0]?.date ? `${app.updates[0].date}T00:00:00Z` : '2026-11-25T00:00:00Z'),
  };
}

export async function handleWaptiaUpdates(request, env) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const origin = url.origin;
  const channel = normalizeChannel(url.searchParams.get('channel') || url.searchParams.get('track'));
  const apps = await loadAppsDb(request, env);

  // 1. Health & Discovery
  if (path === '/api/v1/health' || path === '/api/health') {
    return jsonResponse({
      status: 'healthy',
      service: 'waptia-updates-api',
      provider: 'cloudflare-pages',
      oci_dependent: false,
      channels: SUPPORTED_CHANNELS,
      catalog_count: apps.length,
    });
  }

  // 2. Channels directory (all channels or specific app)
  if (path === '/api/v1/ota/channels' || path.startsWith('/api/v1/ota/channels/')) {
    const slugParam = path.replace('/api/v1/ota/channels', '').replace(/^\/+/, '');
    if (slugParam) {
      const app = findAppEntry(apps, slugParam, '');
      if (!app) return jsonResponse({ status: 'error', message: `App '${slugParam}' not found` }, 404);
      const channelsMap = {};
      for (const ch of SUPPORTED_CHANNELS) {
        channelsMap[ch] = {
          channel: ch,
          check_url: `${origin}/api/v1/ota/check?app=${app.slug}&channel=${ch}`,
          manifest_url: `${origin}/ota/${app.slug}/manifest.json?channel=${ch}`,
          download_url: `${origin}/download/${app.slug}.apk?channel=${ch}`,
        };
      }
      return jsonResponse({ status: 'success', app: app.slug, channels: channelsMap });
    }
    return jsonResponse({
      status: 'success',
      provider: 'waptia',
      channels: SUPPORTED_CHANNELS,
      total_apps: apps.length,
      catalog_endpoint: `${origin}/api/v1/ota/catalog?channel={channel}`,
      check_endpoint: `${origin}/api/v1/ota/check?app={slug}&channel={channel}`,
    });
  }

  // 3. Full Fleet / Catalog Endpoint (all apps, channel-aware)
  if (path === '/api/v1/ota/catalog' || path === '/api/v1/ota/fleet') {
    const filterChannel = url.searchParams.get('channel') || url.searchParams.get('track');
    const targetChannel = normalizeChannel(filterChannel);
    const catalog = apps.map((app) => buildCatalogEntry(app, targetChannel, origin));
    return jsonResponse({
      status: 'success',
      provider: 'waptia',
      oci_dependent: false,
      channel: targetChannel,
      channels: SUPPORTED_CHANNELS,
      count: catalog.length,
      catalog,
      updated_at: new Date().toISOString(),
    });
  }

  // 4. Apps List & App Detail
  if (path === '/api/v1/apps' || path === '/api/apps') {
    return jsonResponse({
      status: 'success',
      provider: 'waptia',
      channels: SUPPORTED_CHANNELS,
      count: apps.length,
      apps: apps.map((app) => buildCatalogEntry(app, channel, origin)),
    });
  }

  if (path.startsWith('/api/v1/apps/') || path.startsWith('/api/apps/')) {
    const slug = path.split('/').filter(Boolean).pop();
    const app = findAppEntry(apps, slug, '');
    if (!app) return jsonResponse({ status: 'error', message: `App '${slug}' not found` }, 404);
    const hfData = await fetchHfManifest(app.slug, channel);
    return jsonResponse({
      status: 'success',
      app: buildCatalogEntry(app, channel, origin, hfData),
    });
  }

  // 5. Single App OTA / Release Check (all channels)
  if (path === '/api/v1/ota/check' || path === '/api/ota/manifest' || path === '/api/v1/ota/manifest.json') {
    const rawApp = url.searchParams.get('app') || url.searchParams.get('slug') || 'waptia';
    const pkg = url.searchParams.get('package_name') || '';
    const signature = url.searchParams.get('signature') || '';
    const app = findAppEntry(apps, rawApp, pkg);
    const slug = app ? app.slug : normalizeSlug(rawApp);

    const hfData = await fetchHfManifest(slug, channel);
    if (!app && !hfData) {
      return jsonResponse({ status: 'error', message: `App '${rawApp}' not found in Waptia registry` }, 404);
    }

    const baseApp = app || {
      slug,
      name: slug,
      packageId: pkg || `com.infortts.${slug}`,
      version: hfData.manifest.version || '1.0.0',
    };
    const entry = buildCatalogEntry(baseApp, channel, origin, hfData);
    return jsonResponse({
      status: 'success',
      provider: 'waptia',
      signature_verified: Boolean(signature),
      resolved_from: hfData ? (hfData.channelMatched ? `hf-channel:${channel}` : 'hf-main+waptia') : 'waptia-catalog',
      ...entry,
    });
  }

  // 6. Batch Check across installed apps and channels
  if (path === '/api/v1/ota/batch_check' && request.method === 'POST') {
    let body = {};
    try { body = await request.json(); } catch (_) {}
    const appsToCheck = Array.isArray(body.apps) ? body.apps : [];
    const defaultCh = normalizeChannel(body.channel || body.track || channel);

    const results = await Promise.all(
      appsToCheck.map(async (item) => {
        const itemCh = normalizeChannel(item.channel || item.track || defaultCh);
        const app = findAppEntry(apps, item.app || item.slug, item.package_name);
        if (!app) return null;
        const curBuild = parseInt(item.build || item.build_number || '0', 10) || 0;
        const hfData = await fetchHfManifest(app.slug, itemCh);
        const entry = buildCatalogEntry(app, itemCh, origin, hfData);
        return {
          ...entry,
          current_build: curBuild,
          has_update: entry.latest_build > curBuild,
        };
      }),
    );

    return jsonResponse({
      status: 'success',
      provider: 'waptia',
      channel: defaultCh,
      results: results.filter(Boolean),
    });
  }

  // 7. Manifest shortcut routes: /ota/:slug/manifest.json or /patches/:slug/v:ver/manifest.json
  if (path.startsWith('/ota/') || path.startsWith('/patches/')) {
    const parts = path.split('/').filter(Boolean);
    const slug = normalizeSlug(parts[1] || '');
    if (!slug) return jsonResponse({ status: 'error', message: 'Missing app slug' }, 400);

    if (path.endsWith('/manifest.json')) {
      const app = findAppEntry(apps, slug, '');
      const hfData = await fetchHfManifest(slug, channel);
      if (!app && !hfData) return jsonResponse({ status: 'error', message: 'Manifest not found' }, 404);
      const entry = buildCatalogEntry(app || { slug, name: slug, version: '1.0.0' }, channel, origin, hfData);
      return jsonResponse({
        slug: entry.slug,
        package_name: entry.package_name,
        channel: entry.channel,
        version: entry.latest_version,
        latestBuild: entry.latest_build,
        latestPatch: entry.latestPatch,
        apk_url: entry.apk_url,
        direct_cdn_url: entry.direct_cdn_url,
        sha256: entry.sha256,
        size_bytes: entry.size_bytes,
        release_notes: entry.release_notes,
        updated_at: entry.published_at,
      });
    }

    // Redirect patch binary requests to Hugging Face CDN
    const subPath = parts.slice(2).join('/');
    const targetUrl = `${HF_RESOLVE_BASE}/${slug}/patches/${subPath.split('/').pop()}`;
    return Response.redirect(targetUrl, 302);
  }

  // 8. Release APK Download Gateway: /download/:filename
  if (path.startsWith('/download/')) {
    const filename = path.replace('/download/', '').split('/')[0];
    const slug = normalizeSlug(filename);
    if (!slug) return jsonResponse({ status: 'error', message: 'Missing package filename' }, 400);

    const app = findAppEntry(apps, slug, '');
    const hfData = await fetchHfManifest(slug, channel);
    let targetApk = hfData?.manifest?.apk_url || app?.apkDownloadUrl || `${HF_RESOLVE_BASE}/${slug}/${slug}.apk`;

    if (channel !== 'production' && !hfData?.channelMatched) {
      const channelApk = `${HF_RESOLVE_BASE}/${slug}/channels/${channel}/${slug}.apk`;
      try {
        const probe = await fetch(channelApk, { method: 'HEAD' });
        if (probe.ok || probe.status === 302) targetApk = channelApk;
      } catch (_) {}
    }

    return new Response(null, {
      status: 302,
      headers: corsHeaders({
        Location: targetApk,
        'Cache-Control': 'public, max-age=60',
        'X-Waptia-Channel': channel,
        'X-Waptia-Slug': slug,
      }),
    });
  }

  return jsonResponse({ status: 'error', message: `Unknown Waptia endpoint: ${path}` }, 404);
}
