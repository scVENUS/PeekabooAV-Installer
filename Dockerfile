FROM ubuntu:18.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /peekaboo

# this approach is fat because we install postfix and amavis as well. We need a
# network API towards amavis to be able to put it in a separate container.
RUN apt-get -y update && \
	apt-get -y dist-upgrade && \
	apt-get install -y \
		python-virtualenv \
		postfix \
		amavisd-new \
		build-essential \
		python3-dev \
		libjpeg-dev \
		zlib1g-dev \
		libmysqlclient-dev && \
	apt-get clean all

COPY PeekabooAV /peekaboo/PeekabooAV/
RUN virtualenv --python=/usr/bin/python3 /opt/peekaboo && \
	cd PeekabooAV && \
	/opt/peekaboo/bin/pip3 install . && \
	/opt/peekaboo/bin/pip3 install mysqlclient
RUN rm -rf /peekaboo

RUN groupadd -g 150 peekaboo
RUN useradd -g 150 -u 150 -m -d /var/lib/peekaboo peekaboo

RUN mkdir /opt/peekaboo/etc
COPY peekaboo/peekaboo.conf /opt/peekaboo/etc/peekaboo.conf.template
RUN touch /opt/peekaboo/etc/peekaboo.conf && \
	chmod 600 /opt/peekaboo/etc/peekaboo.conf && \
	chown peekaboo:root /opt/peekaboo/etc/peekaboo.conf

COPY peekaboo/analyzers.conf /opt/peekaboo/etc/analyzers.conf.template
RUN touch /opt/peekaboo/etc/analyzers.conf && \
	chmod 600 /opt/peekaboo/etc/analyzers.conf && \
	chown peekaboo:root /opt/peekaboo/etc/analyzers.conf

RUN cp /opt/peekaboo/share/doc/peekaboo/ruleset.conf.sample /opt/peekaboo/etc/ruleset.conf

RUN mkdir /run/peekaboo && \
	chown peekaboo: /run/peekaboo

FROM scratch
COPY --from=build / /

USER peekaboo
CMD sed -e "s,{{ peekaboo_db_password }},${PEEKABOO_DB_PASSWORD:-secret},g" \
			-e "s,{{ mariadb_server }},${PEEKABOO_DB_SERVER:-mariadb},g" \
		/opt/peekaboo/etc/peekaboo.conf.template > /opt/peekaboo/etc/peekaboo.conf && \
	sed -e "s,{{ cortex_url }},${PEEKABOO_CORTEX_URL:-http://cortex:9001},g" \
			-e "s,{{ cortex_api_token }},${PEEKABOO_CORTEX_API_TOKEN:-secret},g" \
		/opt/peekaboo/etc/analyzers.conf.template > /opt/peekaboo/etc/analyzers.conf && \
	/opt/peekaboo/bin/peekaboo -c /opt/peekaboo/etc/peekaboo.conf -D
