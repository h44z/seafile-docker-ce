FROM h44z/base-ce:18.04

# For support set local time zone.
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install tzdata -y

WORKDIR /opt/seafile

RUN mkdir -p /etc/my_init.d

# build-time arguments, use them in docker build with --build-arg switch to build different version
ARG SEAFILE_VERSION=7.1.3
ARG LDAP_IGNORE_CERT_CHECK=false

ENV SEAFILE_SERVER=seafile-server
ENV SEAFILE_VERSION=${SEAFILE_VERSION}

RUN mkdir -p /opt/seafile/ && \
    curl -sSL -o - https://download.seadrive.org/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz \
    | tar xzf - -C /opt/seafile/

# For using TLS connection to LDAP/AD server with docker-ce.
RUN find /opt/seafile/ \( -name "liblber-*" -o -name "libldap-*" -o -name "libldap_r*" -o -name "libsasl2.so*" \) -delete

RUN if [ "${LDAP_IGNORE_CERT_CHECK}" = "true" ] ; then echo TLS_REQCERT allow >> /etc/ldap/ldap.conf; fi

ADD scripts/create_data_links.sh /etc/my_init.d/01_create_data_links.sh

COPY scripts /scripts
COPY templates /templates

EXPOSE 80

CMD ["/sbin/my_init", "--", "/scripts/python/start.py"]
