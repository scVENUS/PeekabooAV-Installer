FROM ubuntu:18.04

ARG MODE=api

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /peekaboo

RUN apt-get -y update && \
	apt-get -y dist-upgrade && \
	apt-get install -y \
		python-virtualenv \
		postfix \
		amavisd-new \
		build-essential \
		python-dev \
		libjpeg-dev \
		zlib1g-dev

RUN [ "${MODE}" != "embed" ] || \
	( virtualenv /opt/cuckoo && \
		/opt/cuckoo/bin/pip install cuckoo )

COPY PeekabooAV .
RUN virtualenv /opt/peekaboo && \
	/opt/peekaboo/bin/pip install PeekabooAV

RUN groupadd -g 150 peekaboo
RUN useradd -g 150 -u 150 -m -d /var/lib/peekaboo peekaboo
