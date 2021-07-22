ARG HAPROXY_IMAGE_VERSION=2.2.15-alpine
ARG CERTBOT_IMAGE_VERSION=latest

FROM certbot/certbot:${CERTBOT_IMAGE_VERSION} as certbot

## Define frontend hostname - for SSL purposes
ARG FRONTEND_HOSTNAME="web.rt.test"
RUN certbot certonly --standalone \
    -d ${FRONTEND_HOSTNAME} \
    --staple-ocsp \
    --register-unsafely-without-email \
    --agree-tos

## Merge the certs into the one
RUN cat /etc/letsencrypt/live/${FRONTEND_HOSTNAME}/fullchain.pem \
    /etc/letsencrypt/live/${FRONTEND_HOSTNAME}/privkey.pem \
    | tee /etc/ssl/${FRONTEND_HOSTNAME}/${FRONTEND_HOSTNAME}.pem

FROM haproxy:${HAPROXY_IMAGE_VERSION}

LABEL MAINTAINER="truskul <github.com/truskul>"
LABEL DESCRIPTION="The HAProxy service with auto-generated SSL certificates and preconfigured TLS Termination"
LABEL VERSION="1.0.0"

## Copy the generated certs into the haproxy container
COPY --from=certbot \
     --chown=haproxy:haproxy \
     /etc/ssl/${FRONTEND_HOSTNAME}/${FRONTEND_HOSTNAME}.pem \
     /etc/haproxy/certs/{$FRONTEND_HOSTNAME}.pem

## Copy haproxy.cfg into the container
COPY ./haproxy.cfg /etc/haproxy/haproxy.cfg

## Run HAProxy syntax test
RUN /usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg
RUN haproxy
