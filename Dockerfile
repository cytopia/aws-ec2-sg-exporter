FROM alpine:3.9 as builder

RUN set -x \
	&& apk add --no-cache \
		gcc \
		libffi-dev \
		make \
		musl-dev \
		openssl-dev \
		python3 \
		python3-dev

RUN set -x \
	&& pip3 install --no-cache-dir --no-compile awscli \
	&& rm -r /usr/lib/python3.6/site-packages/awscli/examples \
	&& find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf \
	&& aws --version 2>&1 | grep -E '^aws-cli/[.0-9]+'

RUN set -x \
	&& pip3 install --no-cache-dir --no-compile supervisor \
	&& find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf


FROM alpine:3.9 as production
LABEL \
	maintainer="cytopia <cytopia@everythingcli.org>" \
	repo="https://github.com/cytopia/aws-ec2-sg-exporter"

RUN set -eux \
	&& mkdir -p /var/www \
	&& apk add --no-cache \
		bash \
		bind-tools \
		curl \
		jq \
		python3 \
	&& ln -sf /usr/bin/python3 /usr/bin/python \
	&& find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf

COPY --from=builder /usr/lib/python3.6/site-packages/ /usr/lib/python3.6/site-packages/
COPY --from=builder /usr/bin/aws /usr/bin/aws
COPY --from=builder /usr/bin/supervisord /usr/bin/supervisord

COPY data/docker-entrypoint.sh /docker-entrypoint.sh
COPY data/httpd.py /usr/bin/httpd.py
COPY data/update-metrics.sh /usr/bin/update-metrics.sh

COPY data/etc/supervisord.conf /etc/supervisord.conf
COPY data/src/aws-ec2-sg-exporter /usr/bin/aws-ec2-sg-exporter

ENTRYPOINT ["/docker-entrypoint.sh"]
