FROM alpine:latest AS build

WORKDIR /peekaboo

# libffi-dev required for cffi to compile from source because wheel is missing
# vom python3 -mvenv virtual environment
RUN apk add \
	gcc musl-dev make \
	python3-dev \
	libffi-dev \
	git \
	mariadb-connector-c-dev

# *optionally* pick up a local, potentially modified version of Peekaboo.
# Explicitly copy README.md so list of source files cannot become empty by
# non-matchin glob which would cause COPY to fail.
COPY README.md PeekabooAV* /peekaboo/PeekabooAV/
RUN python3 -mvenv /opt/peekaboo

ARG VERSION=

RUN if [ -d /peekaboo/PeekabooAV/peekaboo ] ; then \
		echo "NOTE: Installing locally-supplied PeekabooAV" && \
		cd PeekabooAV && \
		/opt/peekaboo/bin/pip3 install . ; \
	else \
		echo "NOTE: Installing PeekabooAV release ${VERSION:-latest}" && \
		/opt/peekaboo/bin/pip3 install peekabooav${VERSION:+==${VERSION}} ; \
	fi

RUN /opt/peekaboo/bin/pip3 install mysqlclient aiomysql
RUN find /opt/peekaboo/lib -name "*.so" | xargs strip

RUN addgroup -g 150 peekaboo
RUN adduser -G peekaboo -u 150 -D -h /var/lib/peekaboo peekaboo

RUN mkdir -p /opt/peekaboo/etc

# provide default config from distributed samples - these do not contain
# sensitive data
# prepare for overrides by the entrypoint or directly via volume mounts from
# the outside. Since the entrypoint runs without privileges, these need to be
# set up beforehand and be writeable by the runtime user.
RUN etcdir=/opt/peekaboo/etc ; \
	sampledir=/opt/peekaboo/share/doc/peekaboo ; \
	set -e ; \
	for conf in peekaboo analyzers ruleset ; do \
		cp "$sampledir"/"$conf".conf.sample "$etcdir"/"$conf".conf ; \
		\
		dropdir="$etcdir"/"$conf".conf.d ; \
		entryconfig="$dropdir"/05-entrypoint.conf ; \
		mkdir -p "$dropdir" ; \
		touch "$entryconfig" ; \
		chmod 0600 "$entryconfig" ; \
		chown peekaboo:root "$entryconfig" ; \
	done

FROM alpine:latest
COPY --from=build /opt/peekaboo/ /opt/peekaboo/

RUN addgroup -g 150 peekaboo
RUN adduser -G peekaboo -u 150 -D -h /var/lib/peekaboo peekaboo

RUN apk add --no-cache python3 \
		# this is needed for the python-magic package
		libmagic \
		mariadb-connector-c

COPY entrypoint.sh /opt/
RUN chmod +x /opt/entrypoint.sh

EXPOSE 8100

USER peekaboo
CMD ["/opt/entrypoint.sh"]
