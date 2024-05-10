FROM debian:bookworm-slim
LABEL org.opencontainers.image.authors="christoph.h44z@gmail.com"

ENV TZ=Europe/Vienna

# For support set local time zone.
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    procps python3 python3-dev python3-setuptools python3-pip libmariadb-dev-compat libmariadb-dev \
    libjpeg-dev zlib1g-dev ldap-utils libldap2-dev libsasl2-dev \
    curl sqlite3 tzdata locales memcached libmemcached-dev libffi-dev && \
  rm -f /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python && \
  pip3 install --break-system-packages --timeout=3600 \
    click termcolor colorlog pymysql \
    django==4.2.* future==0.18.* mysqlclient==2.1.* \
    pillow==10.2.* pylibmc captcha==0.5.* markupsafe==2.0.1 jinja2 sqlalchemy==2.0.18 \
    psd-tools django-pylibmc django_simple_captcha==0.6.* pyjwt==2.6.* djangosaml2==1.5.* pysaml2==7.2.* pycryptodome==3.16.* cffi==1.15.1 lxml python-ldap==3.4.3 && \
  sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

ENV DOCKERIZE_VERSION v0.7.0
RUN curl -L https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar -xz -C /usr/local/bin


WORKDIR /opt/seafile

# build-time arguments, use them in docker build with --build-arg switch to build different version
ARG SEAFILE_VERSION=11.0.8

ENV SEAFILE_VERSION=${SEAFILE_VERSION}

RUN mkdir -p /opt/seafile/ /seafile/ && \
    curl -sSL -o - https://download.seadrive.org/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz \
    | tar xzf - -C /opt/seafile/ && \
    ln -s /opt/seafile/seafile-server-${SEAFILE_VERSION} /opt/seafile/seafile-server-latest

COPY scripts /scripts

EXPOSE 8000 8082 8080

ENTRYPOINT ["/scripts/seafile-entrypoint.sh"]
