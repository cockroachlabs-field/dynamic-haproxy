#!/bin/bash
set -e

function buildConfig() {

  local sqlBindPort="26257"
  local httpBindPort="8080"
  local statsBindPort="8081"

  local sqlListenPort="26257"
  local httpListenPort="8080"
  local healthCheckPort="8080"

  local nodeList=$NODES

  if [[ -n "$SQL_BIND_PORT" ]]; then
    echo "found SQL_BIND_PORT [${SQL_BIND_PORT}]"
    sqlBindPort = $SQL_BIND_PORT
  fi

  if [[ -n "$HTTP_BIND_PORT" ]]; then
    echo "found HTTP_BIND_PORT [${HTTP_BIND_PORT}]"
    httpBindPort = $HTTP_BIND_PORT
  fi

  if [[ -n "$STATS_BIND_PORT" ]]; then
    echo "found STATS_BIND_PORT [${STATS_BIND_PORT}]"
    statsBindPort = $STATS_BIND_PORT
  fi

  if [[ -n "$SQL_LISTEN_PORT" ]]; then
    echo "found SQL_LISTEN_PORT [${SQL_LISTEN_PORT}]"
    sqlListenPort = $SQL_LISTEN_PORT
  fi

  if [[ -n "$HTTP_LISTEN_PORT" ]]; then
    echo "found HTTP_LISTEN_PORT [${HTTP_LISTEN_PORT}]"
    httpListenPort = $HTTP_LISTEN_PORT
  fi

  if [[ -n "$HEALTH_CHECK_PORT" ]]; then
    echo "found HTTP_LISTEN_PORT [${HEALTH_CHECK_PORT}]"
    healthCheckPort = $HEALTH_CHECK_PORT
  fi

  local sqlServerBlock=""

  for node in $nodeList ; do
    sqlServerBlock+="server $node $node:${sqlListenPort} check port ${healthCheckPort}"$'\n'
  done

  local httpServerBlock=""

  for node in $nodeList ; do
    httpServerBlock+="server $node $node:${httpListenPort} check port ${healthCheckPort}"$'\n'
  done

  cat > /usr/local/etc/haproxy/haproxy.cfg <<EOF
global
    log stdout format raw local0 info
    maxconn 4096
    nbproc 1
    nbthread 4

defaults
    log                 global
    timeout connect     5m
    timeout client      30m
    timeout server      30m
    option              clitcpka
    option              tcplog

listen cockroach-sql
    bind :${sqlBindPort}
    mode tcp
    balance roundrobin
    option httpchk GET /health?ready=1
    ${sqlServerBlock}

listen cockroach-http
    bind :${httpBindPort}
    mode tcp
    balance roundrobin
    option httpchk GET /health
    ${httpServerBlock}

listen stats
    bind :${statsBindPort}
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
EOF

}

if [[ -z "$NODES" ]]; then
    echo "The NODES environment variable is required.  It is an space delimited list of CockroachDB node hostnames.  For example 'node1 node2 node3'" 1>&2
    exit 1
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	shift # "haproxy"
	# if the user wants "haproxy", let's add a couple useful flags
	#   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
	#   -db -- disables background mode
	set -- haproxy -W -db "$@"
fi

buildConfig

exec "$@"