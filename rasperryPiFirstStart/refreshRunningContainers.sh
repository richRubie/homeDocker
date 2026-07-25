#!/bin/bash

set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed or not on PATH" >&2
  exit 1
fi

echo "Running containers:"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

mapfile -t project_dirs < <(
  docker ps -q |
    while read -r container_id; do
      [ -n "$container_id" ] || continue
      docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "$container_id" 2>/dev/null || true
    done |
    awk 'NF && !seen[$0]++'
)

if [ "${#project_dirs[@]}" -eq 0 ]; then
  echo "No Docker Compose projects found among the running containers." >&2
  exit 0
fi

for project_dir in "${project_dirs[@]}"; do
  if [ -z "$project_dir" ] || [ ! -d "$project_dir" ]; then
    echo "Skipping missing project directory: $project_dir" >&2
    continue
  fi

  echo "Refreshing compose project in: $project_dir"
  (
    cd "$project_dir"
    docker compose pull
    docker compose up -d --force-recreate
  )
done