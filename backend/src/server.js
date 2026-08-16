
import http from 'node:http';
import { URL } from 'node:url';

const port = Number(process.env.PORT || 8787);
const braveApiKey = (process.env.BRAVE_SEARCH_API_KEY || '').trim();
const rateWindowMs = 60_000;
const rateMax = Number(process.env.RATE_LIMIT_PER_MINUTE || 60);
const clients = new Map();
const allowedOrigins = new Set(
  (process.env.ALLOWED_ORIGINS || process.env.ALLOWED_ORIGIN || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean),
);
const requestTimeoutMs = Number(process.env.REQUEST_TIMEOUT_MS || 10_000);

const blockedHosts = new Set([
  'google.com', 'google.co.in', 'google.co.uk', 'google.ca', 'google.com.au',
  'google.de', 'google.fr', 'google.es', 'google.it', 'google.co.jp',
  'googleusercontent.com', 'googleapis.com', 'gstatic.com',
]);

function blocked(hostname) {
  const host = hostname.toLowerCase().replace(/^www\./, '');
  return [...blockedHosts].some((h) => host === h || host.endsWith(`.${h}`));
}

function safeUrl(value) {
  try {
    const url = new URL(value);
    return ['http:', 'https:'].includes(url.protocol) && !blocked(url.hostname);
  } catch {
    return false;
  }
}

function json(res, status, body, origin = '') {
  const headers = {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
    'x-frame-options': 'DENY',
    'referrer-policy': 'no-referrer',
    'permissions-policy': 'camera=(), microphone=(), geolocation=()',
    'cross-origin-resource-policy': 'same-origin',
    'access-control-allow-headers': 'content-type',
    'access-control-allow-methods': 'GET, OPTIONS',
  };
  if (origin && allowedOrigins.has(origin)) {
    headers['access-control-allow-origin'] = origin;
    headers.vary = 'Origin';
  }
  res.writeHead(status, headers);
  res.end(JSON.stringify(body));
}

function errorBody(type, message) {
  return { error: { type, message } };
}

function rateLimited(req) {
  const now = Date.now();
  const key = req.socket.remoteAddress || 'unknown';
  // Keep the in-memory limiter bounded for long-running development servers.
  for (const [client, entry] of clients) {
    if (now - entry.started >= rateWindowMs) clients.delete(client);
  }
  const old = clients.get(key);
  if (!old || now - old.started >= rateWindowMs) {
    clients.set(key, { started: now, count: 1 });
    return false;
  }
  old.count += 1;
  return old.count > rateMax;
}

async function search(query, category = 'web') {
  if (!braveApiKey) {
    return [{
      title: `Optimistic Search — ${query}`,
      url: '',
      description: 'Native search is offline. Configure BRAVE_SEARCH_API_KEY for live results.',
    }];
  }

  const endpoint = new URL('https://api.search.brave.com/res/v1/web/search');
  endpoint.searchParams.set('q', query);
  endpoint.searchParams.set('country', 'IN');
  endpoint.searchParams.set('search_lang', 'en');
  endpoint.searchParams.set('count', '20');

  if (category === 'news') endpoint.pathname = '/res/v1/news/search';
  if (category === 'images') endpoint.pathname = '/res/v1/images/search';
  if (category === 'videos') endpoint.pathname = '/res/v1/videos/search';

  let response;
  let lastError;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      response = await fetch(endpoint, {
        headers: {
          Accept: 'application/json',
          'X-Subscription-Token': braveApiKey,
        },
        signal: AbortSignal.timeout(requestTimeoutMs),
      });
      if (response.ok) break;
      lastError = new Error(`Search provider returned ${response.status}`);
    } catch (error) {
      lastError = error;
    }
  }
  if (!response?.ok) throw lastError || new Error('Search provider unavailable.');

  const data = await response.json();
  const raw = Array.isArray(data?.web?.results)
    ? data.web.results
    : Array.isArray(data?.results)
        ? data.results
        : [];

  return raw
      .map((item) => ({
        title: String(item.title || 'Untitled'),
        url: String(item.url || item.link || ''),
        description: String(item.description || item.snippet || ''),
      }))
      .filter((item) => safeUrl(item.url));
}

const server = http.createServer(async (request, response) => {
  const origin = String(request.headers.origin || '').trim();
  try {
    if (request.method === 'OPTIONS') {
      if (origin && !allowedOrigins.has(origin)) {
        return json(response, 403, errorBody('cors', 'Origin is not allowed.'), origin);
      }
      return json(response, 204, {}, origin);
    }
    if (request.method !== 'GET') {
      return json(response, 405, errorBody('validation', 'Method not allowed.'), origin);
    }
    if (origin && !allowedOrigins.has(origin)) {
      return json(response, 403, errorBody('cors', 'Origin is not allowed.'), origin);
    }
    if (rateLimited(request)) {
      return json(response, 429, errorBody('rate_limit', 'Rate limit exceeded.'), origin);
    }

    const requestUrl = new URL(
      request.url || '/',
      `http://${request.headers.host || '127.0.0.1'}`,
    );

    if (requestUrl.pathname === '/health') {
      return json(response, 200, {
        ok: true,
        service: 'optimistic-gateway',
        searchEngine: 'optimistic-native',
        googleRedirect: false,
      }, origin);
    }

    if (requestUrl.pathname === '/api/search') {
      const query = (requestUrl.searchParams.get('q') || '').trim();
      const category = (requestUrl.searchParams.get('category') || 'web').trim();

      if (!query) {
        return json(response, 400, errorBody('validation', 'Query is required.'), origin);
      }
      if (query.length > 500) {
        return json(response, 413, errorBody('validation', 'Query is too long.'), origin);
      }
      if (!['web', 'images', 'news', 'videos', 'shopping'].includes(category)) {
        return json(response, 400, errorBody('validation', 'Unsupported category.'), origin);
      }

      // Brave does not expose a dedicated shopping endpoint in this project.
      // Keep shopping as a clearly labelled web-search category until a
      // dedicated provider is integrated.
      const effectiveCategory = category === 'shopping' ? 'web' : category;
      const results = await search(query, effectiveCategory);
      return json(response, 200, {
        results,
        native: true,
        category,
        externalSearchPage: false,
      }, origin);
    }

    return json(response, 404, errorBody('not_found', 'Not found.'), origin);
  } catch (error) {
    console.error(error);
    return json(
      response,
      500,
      errorBody('server', 'Internal server error.'),
      origin,
    );
  }
});

server.listen(port, '0.0.0.0', () =>
  console.log(`Optimistic gateway listening on ${port}`),
);
