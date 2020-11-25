# dynamic-haproxy
A Docker image that simplifies the deployment of HAProxy in front of a CockroachDB Docker cluster.  This image is intended to be used for local development, testing and demos.  The following `docker-compose.yml` snippet highlights how it may be used, specifically the `lb` service. 

```yaml
services:

  crdb-0:
    hostname: crdb-0
    ...

  crdb-1:
    hostname: crdb-1
    ...

  crdb-2:
    hostname: crdb-2
    ...

  lb:
    container_name: lb
    hostname: lb
    image: timveil/dynamic-haproxy:latest
    ports:
      - "26257:26257"
      - "8080:8080"
      - "8081:8081"
    environment:
      - NODES=crdb-0 crdb-1 crdb-2
    links:
      - crdb-0
      - crdb-1
      - crdb-2
```

The following `environment` variables are supported by the Docker image.
* `NODES` - __Required__. A space-delimited list of CockroachDB node hostnames in the cluster that will be fronted by HAProxy.  For example, `crdb-0 crdb-1 crdb-2`.
* `DB_BIND_PORT` - The database port that HAProxy will `bind` and ultimately expose.  The default is `26257`.
* `WEB_BIND_PORT` - The web port that HAProxy will `bind` and ultimately expose.  The default is `8080`.
* `STATS_BIND_PORT` - The stats port that HAProxy will `bind` and ultimately expose.  The default is `8081`.
* `DB_LISTEN_PORT` - The port that the CockroachDB node communicates over.
* `WEB_LISTEN_PORT` - The port that the CockroachDB admin ui communicates over.
* `HEALTH_PORT` - The port that the CockroachDB uses for health checks.

## Building the Image
```bash
docker build --no-cache -t timveil/dynamic-haproxy:latest .
```

## Publishing the Image
```bash
docker push timveil/dynamic-haproxy:latest
```

## Running the Image
```bash
docker run -it timveil/dynamic-haproxy:latest
```

running the image with environment variables
```bash
docker run \
    --env "NODES=crdb-0 crdb-1 crdb-2" \
    -it timveil/dynamic-haproxy:latest
```