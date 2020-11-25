#!/bin/bash
set -e

function buildConfig() {

  local db_bind_port="26257"
  local web_bind_port="8080"
  local stats_bind_port="8081"

  local db_listen_port="26257"
  local web_listen_port="8080"
  local health_port="8080"

  local nodes=$NODES

  if [[ -n "$DB_BIND_PORT" ]]; then
    echo "found DB_BIND_PORT [${DB_BIND_PORT}]"
    db_bind_port = $DB_BIND_PORT
  fi

  if [[ -n "$WEB_BIND_PORT" ]]; then
    echo "found WEB_BIND_PORT [${WEB_BIND_PORT}]"
    web_bind_port = $WEB_BIND_PORT
  fi

  if [[ -n "$STATS_BIND_PORT" ]]; then
    echo "found STATS_BIND_PORT [${STATS_BIND_PORT}]"
    stats_bind_port = $STATS_BIND_PORT
  fi

  if [[ -n "$DB_LISTEN_PORT" ]]; then
    echo "found DB_LISTEN_PORT [${DB_LISTEN_PORT}]"
    db_listen_port = $DB_LISTEN_PORT
  fi

  if [[ -n "$WEB_LISTEN_PORT" ]]; then
    echo "found web_listen_port [${WEB_LISTEN_PORT}]"
    web_listen_port = $WEB_LISTEN_PORT
  fi

  if [[ -n "$HEALTH_PORT" ]]; then
    echo "found web_listen_port [${HEALTH_PORT}]"
    health_port = $HEALTH_PORT
  fi

  local jdbc_block=""

  for node in $nodes ; do
    jdbc_block+="server $node $node:${db_listen_port} check port ${health_port}"$'\n'
  done

  local ui_block=""

  for node in $nodes ; do
    ui_block+="server $node $node:${web_listen_port} check port ${health_port}"$'\n'
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

listen cockroach-jdbc
    bind :${db_bind_port}
    mode tcp
    balance roundrobin
    option httpchk GET /health?ready=1
    ${jdbc_block}

listen cockroach-ui
    bind :${web_bind_port}
    mode tcp
    balance roundrobin
    option httpchk GET /health
    ${ui_block}

listen stats
    bind :${stats_bind_port}
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
EOF

cat /usr/local/etc/haproxy/haproxy.cfg

}

if [[ -z "$NODES" ]]; then
    echo "The NODES environment variable is Required.  It is an space delimited list of CockroachDB node Hostnames.  For example 'node1 node2 node3'" 1>&2
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