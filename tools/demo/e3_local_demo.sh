#!/usr/bin/env bash
set -euo pipefail

# Deliberately fixed to the local Docker Desktop Supabase port. No linked URL or
# project ref is accepted, even if one is present in the environment.
action="${1:-}"
database="${2:-postgres}"
case "$action" in seed|cleanup) ;; *) echo 'Usage: e3_local_demo.sh seed|cleanup [postgres|e3_demo_dryrun_*]' >&2; exit 2 ;; esac
case "$database" in postgres|e3_demo_dryrun_*) ;; *) echo 'Refusing nonlocal database name' >&2; exit 2 ;; esac
if [[ "$database" == 'postgres' && "${E3_DEMO_APPROVED:-}" != '1' ]]; then
  echo 'Effective local writes require explicit per-run approval (E3_DEMO_APPROVED=1)' >&2
  exit 2
fi
if [[ "$(docker context show)" != 'desktop-linux' ]]; then
  echo 'Docker Desktop context desktop-linux is required' >&2
  exit 2
fi
container='supabase_db_flutterapp'
if ! docker ps --format '{{.Names}}' | grep -x "$container" >/dev/null; then
  echo "Local database container $container is not running" >&2
  exit 2
fi
# 127.0.0.1:54322 must be this container's published Postgres port, and the SQL guard
# checks that the server it reaches reports this container's own IP.
if ! docker port "$container" 5432/tcp | grep -E '^(0\.0\.0\.0|127\.0\.0\.1):54322$' >/dev/null; then
  echo "Port 54322 is not published by $container" >&2
  exit 2
fi
read -r -a container_ips <<<"$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$container")"
if [[ "${#container_ips[@]}" -ne 1 ]]; then
  echo "Expected exactly one network IP for $container" >&2
  exit 2
fi
export E3_LOCAL_DB_IP="${container_ips[0]}"
# libpq environment (PGHOSTADDR, PGSERVICE, ...) must not redirect the fixed URL.
while IFS= read -r name; do unset "$name"; done < <(compgen -e | grep '^PG' || true)

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
local_url="postgresql://postgres:postgres@127.0.0.1:54322/$database"
if [[ "$action" == 'seed' ]]; then
  psql "$local_url" -X -v ON_ERROR_STOP=1 -v e3_local_db_ip="$E3_LOCAL_DB_IP" \
    -f "$repo_root/supabase/snippets/step_e3_demo_seed.sql"
else
  python3 "$repo_root/tools/demo/cleanup_e3_demo.py" "$database"
fi
