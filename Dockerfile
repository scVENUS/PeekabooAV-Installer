FROM debian:bullseye-slim AS build

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /peekaboo

RUN apt-get -y update && \
	apt-get install -y \
		python3-virtualenv \
		build-essential \
		python3-dev \
		libjpeg-dev \
		zlib1g-dev \
		git \
		libmariadb-dev

COPY PeekabooAV /peekaboo/PeekabooAV/
RUN virtualenv /opt/peekaboo && \
	cd PeekabooAV && \
	/opt/peekaboo/bin/pip3 install . && \
	/opt/peekaboo/bin/pip3 install mysqlclient aiomysql && \
	find /opt/peekaboo/lib -name "*.so" | xargs strip

RUN groupadd -g 150 peekaboo
RUN useradd -g 150 -u 150 -m -d /var/lib/peekaboo peekaboo

RUN mkdir -p /opt/peekaboo/etc
COPY peekaboo/peekaboo.conf /opt/peekaboo/etc/peekaboo.conf.template
RUN touch /opt/peekaboo/etc/peekaboo.conf && \
	chmod 600 /opt/peekaboo/etc/peekaboo.conf && \
	chown peekaboo:root /opt/peekaboo/etc/peekaboo.conf

COPY peekaboo/analyzers.conf /opt/peekaboo/etc/analyzers.conf.template
RUN touch /opt/peekaboo/etc/analyzers.conf && \
	chmod 600 /opt/peekaboo/etc/analyzers.conf && \
	chown peekaboo:root /opt/peekaboo/etc/analyzers.conf

RUN cp /opt/peekaboo/share/doc/peekaboo/ruleset.conf.sample /opt/peekaboo/etc/ruleset.conf

FROM debian:bullseye-slim
COPY --from=build /opt/peekaboo/ /opt/peekaboo/
ENV DEBIAN_FRONTEND=noninteractive

RUN groupadd -g 150 peekaboo
RUN useradd -g 150 -u 150 -m -d /var/lib/peekaboo peekaboo

RUN apt-get update -y && \
	apt-get install -y --no-install-suggests \
		python3-minimal \
		python3-distutils \
		# this is needed for the python-magic package
		libmagic1 \
		libmariadb3 && \
	apt-get clean all && \
	find /var/lib/apt/lists -type f -delete

COPY entrypoint.sh /opt/
RUN chmod +x /opt/entrypoint.sh

EXPOSE 8100

USER peekaboo
CMD ["/opt/entrypoint.sh"]
