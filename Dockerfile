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

# *optionally* pick up a local, potentially modified version of Peekaboo.
# Explicitly copy README.md so list of source files cannot become empty by
# non-matchin glob which would cause COPY to fail.
COPY README.md PeekabooAV* /peekaboo/PeekabooAV/
RUN virtualenv /opt/peekaboo

ARG VERSION=

RUN if [ -d /peekaboo/PeekabooAV/peekaboo ] ; then \
		echo "NOTE: Installing locally-supplied PeekabooAV" && \
		cd PeekabooAV && \
		/opt/peekaboo/bin/pip3 install . ; \
	else \
		echo "NOTE: Installing PeekabooAV release ${VERSION:-latest}" && \
		/opt/peekaboo/bin/pip3 install peekabooav${VERSION:+==${VERSION}} ; \
	fi

RUN /opt/peekaboo/bin/pip3 install mysqlclient aiomysql && \
	find /opt/peekaboo/lib -name "*.so" | xargs strip

RUN groupadd -g 150 peekaboo
RUN useradd -g 150 -u 150 -m -d /var/lib/peekaboo peekaboo

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
