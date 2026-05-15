// Патч @vesp/frontend get-api.js для решения NAT hairpin loopback на debianOCR.
// SSR-fetch (import.meta.server) идёт на http://nginx/ — internal docker DNS внутри
// feelyoga_default сети. Client-side fetch остаётся на публичный SITE_URL.
// См. reference_hairpin_ssr_hang.md в глобальной памяти ~/.claude/memory/.
//
// Монтируется в контейнер node через docker-compose.override.yml:
//   volumes:
//     - ./.local/vesp/get-api.js:/vesp/frontend/node_modules/@vesp/frontend/dist/runtime/utils/get-api.js

import { useRuntimeConfig } from "#imports";
export function getApiUrl() {
  const config = useRuntimeConfig();
  const SITE_URL = import.meta.server
    ? "http://nginx/"
    : String(config.public.SITE_URL || "http://localhost");
  const API_URL = String(config.public.API_URL || "api");
  const url = /:\/\//.test(API_URL) ? API_URL : [
    SITE_URL.endsWith("/") ? SITE_URL.slice(0, -1) : SITE_URL,
    API_URL.startsWith("/") ? API_URL.substring(1) : API_URL
  ].join("/");
  return url.endsWith("/") ? url : url + "/";
}
export function getImageLink(file, options, prefix) {
  const config = useRuntimeConfig();
  const SITE_URL = String(config.public.SITE_URL || "http://localhost");
  const API_URL = String(config.public.API_URL || "api");
  const baseUrl = /:\/\//.test(API_URL) ? API_URL : [
    SITE_URL.endsWith("/") ? SITE_URL.slice(0, -1) : SITE_URL,
    API_URL.startsWith("/") ? API_URL.substring(1) : API_URL
  ].join("/");
  const apiUrl = baseUrl.endsWith("/") ? baseUrl : baseUrl + "/";
  const params = [apiUrl.slice(0, -1), prefix || "image", file.uuid || file.id];
  if (file.updated_at) {
    if (!options) { options = {}; }
    if (!options.fm) { options.fm = "webp"; }
    options.t = file.updated_at.split(".").shift()?.replaceAll(/\D/g, "");
  }
  return params.join("/") + "?" + new URLSearchParams(options).toString();
}
