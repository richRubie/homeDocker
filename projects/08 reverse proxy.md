# Reverse proxy for all web UIs

Put every web interface behind a single nginx container on host 80/443, terminating
TLS with the existing wildcard `*.rubie-todd.uk` cert. Home Assistant and Unifi stay
on `network_mode: host` and are reached via `host-gateway`; Pi-hole vacates 80/443
for a shared docker bridge. Pi-hole Local DNS Records point the new hostnames at the
Pi's LAN IP.

## Port map after the change

| Host port | Owner |
|---|---|
| 80, 443 | nginx proxy (new) |
| 8089 / 8445 | Pi-hole admin (moved from 80/443) |
| 631 | CUPS (unchanged) |
| 8123 | Home Assistant - plain HTTP (2053 retired) |
| 8080/8443/8880/8843/6789/3478/10001 | Unifi (host net) |
| 8081 | Zigbee2MQTT frontend (host net) |
| 1883 | Mosquitto (host net) |
| 53/67 | Pi-hole DNS/DHCP (unchanged) |

## Hostname routing

| Hostname | Upstream | Notes |
|---|---|---|
| ha.rubie-todd.uk | http://host-gateway:8123 | websocket upgrade |
| unifi.rubie-todd.uk | https://host-gateway:8443 | `proxy_ssl_verify off` |
| pihole.rubie-todd.uk | http://pihole:80 | via shared bridge, resolved by name |
| cups.rubie-todd.uk | http://host-gateway:631 | |
| z2m.rubie-todd.uk | http://host-gateway:8081 | websocket upgrade |

## Steps

### Phase 1 - proxy scaffold

1. Create `reverseProxy/docker-compose.yaml`: `nginx:alpine`,
   `container_name: reverse-proxy`, ports `80:80`/`443:443`,
   `extra_hosts: - "host-gateway:host-gateway"`, mounts for `./volumes/conf.d`,
   `./volumes/nginx.conf` and `../secrets/cert:/etc/nginx/certs:ro`, label
   `com.github.richr.cert-reload=true`, shared `proxy` bridge network.
2. Add `reverseProxy/volumes/conf.d/00-common.conf` - shared `ssl_*` directives
   against `fullchain.pem`/`privkey.pem`, forwarded-header defaults, and a `map`
   for `$connection_upgrade`.
3. One server block per service in `conf.d/`, plus a port-80 catch-all doing
   `return 301 https://$host$request_uri`.
4. `reverseProxy/readme.md` covering the reload procedure and how to add a host.

### Phase 2 - backend changes

5. `pihole/piholev0/docker-compose.yaml` - remap `80:80` to `8089:80` and
   `443:443` to `8445:443`; attach to the shared `proxy` network so nginx can
   resolve `pihole` by name. Keep the TLS env vars as a direct-access fallback.
6. **Home Assistant - UI only.** Settings > System > Network:
   - clear the SSL certificate/key, set the listen port back to 8123
   - enable Trust X-Forwarded-For, add `172.16.0.0/12` as a trusted proxy
   - set Internal URL and External URL to `https://ha.rubie-todd.uk`
7. `homeAssistant/volumes/config/configuration.yaml` - delete the stale
   `internal_url: https://pi3.rubie-todd.uk:2053` so YAML doesn't fight the UI
   setting. No `http:` block is added.
8. `homeAssistant/docker-compose.yaml` - drop the `../secrets/cert:/config/ssl:ro`
   mount and the `com.github.richr.cert-reload=true` label; HA no longer consumes
   certs and leaves the renewal restart set.
9. CUPS - `cupsd` returns HTTP 400 for an unrecognised `Host` header. Needs a
   mounted `cups/volumes/cupsd.conf` with `ServerAlias *`, `Listen 0.0.0.0:631`
   and `Allow @LOCAL`.
10. Zigbee2MQTT - frontend already on 8081 with SSL commented out; correct as-is.
    Optionally pin `frontend.host: 0.0.0.0`. No compose change.
11. Unifi - no compose change. If AP adoption fails, set "Override inform host"
    to the Pi's IP.

### Phase 3 - DNS and cert reload

12. Add five Pi-hole Local DNS Records mapping the subdomains to the Pi's LAN IP.
13. Wire nginx into renewal. The label from step 1 makes
    `refreshRunningContainers.sh` restart it, but
    `docker exec reverse-proxy nginx -s reload` is gentler and likely warrants a
    special case in that script.

## Files touched

- `reverseProxy/docker-compose.yaml`, `reverseProxy/volumes/nginx.conf`,
  `reverseProxy/volumes/conf.d/*.conf` - new; model the cert mount and
  cert-reload label on `unifi/docker-compose.yaml`
- `pihole/piholev0/docker-compose.yaml` - `ports:` list, new `networks:` key
- `homeAssistant/volumes/config/configuration.yaml` - remove stale `internal_url`
- `homeAssistant/docker-compose.yaml` - remove cert mount + cert-reload label
- `cups/docker-compose.yml` + new `cups/volumes/cupsd.conf`
- `rasperryPiFirstStart/refreshRunningContainers.sh` - reload-instead-of-restart
- `rasperryPiFirstStart/certRefresh.sh` - no change; 640 `root:certreaders` files
  are readable by nginx's root process

## Verification

1. `docker compose config` in `reverseProxy/` and `pihole/piholev0/`
2. `docker exec reverse-proxy nginx -t`
3. `curl -I http://ha.rubie-todd.uk` gives 301;
   `curl -I https://ha.rubie-todd.uk` gives 200 with a valid LE chain
4. Browser-check all five hosts; confirm websockets via live HA entity updates,
   the Unifi topology map and the Z2M network map
5. `sudo ss -tlnp | grep -E ':(80|443|2053|8089|8123|8445)'` - nginx on 80/443,
   HA on 8123, nothing on 2053
6. HA Settings > System > Logs shows no untrusted-proxy warnings, and the auth log
   records real client IPs rather than the nginx container IP
7. Certbot renewal dry-run; confirm nginx reloads and HA is absent from the
   restart set

## Decisions

- Plain nginx container, not Caddy/Traefik/NPM
- LAN-only; no router port-forward. Remote access stays on Tailscale, so no
  fail2ban/auth-hardening pass in this project
- HA network settings are managed exclusively through the HA UI; no `http:` block
  will be added to YAML
- HA's own TLS is retired along with port 2053 (arbitrary/legacy, nothing external
  depends on it)
- HA and Unifi keep `network_mode: host` to preserve mDNS discovery and L2 AP
  adoption
- OpenClaw stays Tailscale-only; Mosquitto/MQTT is not HTTP and is out of scope

## Open questions

1. Cert reload: `nginx -s reload` special case (zero downtime) vs letting the
   existing label restart the container (~1s blip, no script change)
2. Auth for CUPS and Zigbee2MQTT, which have no login of their own - nginx basic
   auth, leave open on LAN, or Z2M's built-in `frontend.auth_token`
3. Fallback ports: leave 8123/8443/8089 LAN-reachable as break-glass, or bind them
   to `127.0.0.1` so the proxy is the only door
