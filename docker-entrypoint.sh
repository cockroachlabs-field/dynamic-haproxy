#!/bin/bash
set -e

function buildConfig() {

  local _sql_bind_port="26257"
  local _http_bind_port="8080"
  local _stats_bind_port="8081"

  local _sql_listen_port="26257"
  local _http_listen_port="8080"
  local _health_check_port="8080"

  local _node_list=$NODES

  if [[ -n "$SQL_BIND_PORT" ]]; then
    echo "found SQL_BIND_PORT [${SQL_BIND_PORT}]"
    _sql_bind_port=$SQL_BIND_PORT
  fi

  if [[ -n "$HTTP_BIND_PORT" ]]; then
    echo "found HTTP_BIND_PORT [${HTTP_BIND_PORT}]"
    _http_bind_port=$HTTP_BIND_PORT
  fi

  if [[ -n "$STATS_BIND_PORT" ]]; then
    echo "found STATS_BIND_PORT [${STATS_BIND_PORT}]"
    _stats_bind_port=$STATS_BIND_PORT
  fi

  if [[ -n "$SQL_LISTEN_PORT" ]]; then
    echo "found SQL_LISTEN_PORT [${SQL_LISTEN_PORT}]"
    _sql_listen_port=$SQL_LISTEN_PORT
  fi

  if [[ -n "$HTTP_LISTEN_PORT" ]]; then
    echo "found HTTP_LISTEN_PORT [${HTTP_LISTEN_PORT}]"
    _http_listen_port=$HTTP_LISTEN_PORT
  fi

  if [[ -n "$HEALTH_CHECK_PORT" ]]; then
    echo "found HTTP_LISTEN_PORT [${HEALTH_CHECK_PORT}]"
    _health_check_port=$HEALTH_CHECK_PORT
  fi

  local _sql_server_block=""

  for node in $_node_list ; do
    _sql_server_block+="server $node $node:${_sql_listen_port} check port ${_health_check_port}"$'\n'
  done

  local _http_server_block=""

  for node in $_node_list ; do
    _http_server_block+="server $node $node:${_http_listen_port} check port ${_health_check_port}"$'\n'
  done

  cat > /usr/local/etc/haproxy/haproxy.cfg <<EOF
global
    log stdout format raw local0 info
    maxconn 4096
    nbproc 1
    nbthread 4

defaults
    log                 global
    timeout connect     30m
    timeout client      30m
    timeout server      30m
    option              clitcpka
    option              tcplog

listen cockroach-sql
    bind :${_sql_bind_port}
    mode tcp
    balance roundrobin
    option httpchk GET /health?ready=1
    ${_sql_server_block}

listen cockroach-http
    bind :${_http_bind_port}
    mode tcp
    balance roundrobin
    option httpchk GET /health
    ${_http_server_block}

listen stats
    bind :${_stats_bind_port}
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
EOF

}

if [[ -z "$NODES" ]]; then
    echo "The NODES environment variable is required.  It is a space delimited list of CockroachDB node hostnames.  For example 'node1 node2 node3'" 1>&2
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