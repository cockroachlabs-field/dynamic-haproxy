FROM haproxy:2.6

USER root

RUN apt-get update && apt-get upgrade -y

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-V", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
