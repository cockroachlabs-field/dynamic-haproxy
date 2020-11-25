#!/bin/bash


function buildConfig() {

  db_bind_port="26257"
  web_bind_port="8080"
  stats_bind_port="8081"

  db_listen_port="26257"
  web_listen_port="8080"
  health_port="8080"

  nodes="db1 db2 db3 db4"

  jdbc_block=""

  for node in $nodes ; do
    jdbc_block+="server $node $node:${db_listen_port} check port ${health_port}"$'\n'
  done

  ui_block=""

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