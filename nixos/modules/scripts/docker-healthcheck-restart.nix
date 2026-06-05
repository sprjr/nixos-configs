{ pkgs, ... }:

let
  watcherScript = pkgs.writeShellScript "docker-health-watcher" ''
    ${pkgs.docker}/bin/docker events \
    --filter 'event=health_status' \
    --format '{{.Actor.Attributes.name}} {{.Status}}' \
  | while IFS= read -r line; do
    container=$(cut -d' ' -f1 <<< "$line")
    status=$(cut -d' ' -f2- <<< "$line")

    [[ "$status" != "health_status: unhealthy" ]] && continue

    logs=$(${pkgs.docker}/bin/docker logs --tail 75 "$container" 2>&1 | tail -c 3800)

    ${pkgs.curl}/bin/curl -s -X POST \
      -H "Title: [Docker] Unhealthy: $container" \
      -H "Priority: high" \
      -H "Tags: volcano, whale" \
      --data-binary "Container '$container' entered unhealthy state. Restarting.

=== Last Logs ===
$logs" \
      http://100.119.239.121:55455/rawliyosh-administration-notification-network-hso
