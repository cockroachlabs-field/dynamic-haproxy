FROM haproxy:2.3

LABEL maintainer="tjveil@gmail.com"

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]

EXPOSE 26257
EXPOSE 8080
EXPOSE 8081