Kubernetes
==========

This directory provides a helm chart which implements a simple testing pipeline
setup for PeekabooAV including Cortex with FileInfo analyzer as analysis
backend. Postfix and rspamd are used for email ingress.

Installation
------------

Install using helm:

``` shell
helm repo add peekaboo https://scvenus.github.io/PeekabooAV-Installer/
helm install pipeline --namespace pipeline --create-namespace peekaboo/peekabooav-pipeline --values peekabooav-pipeline-values.yaml
```

Or from local repo checkout:

``` shell
helm upgrade --install --namespace pipeline --create-namespace pipeline . --values=values.yaml
```

At a minimum, the following values need to be adjusted/overridden:

``` yaml
cortex-setup:
  cortex:
    apiToken: <cortex API token>
    adminPassword: <admin password>

mariadb:
  auth:
    password: <db password>
    rootPassword: <root password>

peekabooav:
  cortex:
    apiToken: <cortex API token>
  db:
    password: <db password>
```

The passwords can be generated using e.g. `pwgen -snc 17` and the API token
using e.g. `openssl rand -hex 32`.
The important part is that `<db password>` and `<cortex API token>` from above
are identical in the two places they're used.

**_NOTE:_**: Unfortunately there's a helm convention of prepending resource
names with the release name.
Unfortunately again, the chosen release name can not be automatically
interpolated in `values.yaml`.
So if you change the release name from `pipeline` to something else, be sure to
change all occurences of `pipeline` in `values.yaml` as well.

**_NOTE:_**: Helm's convention of prepending resource names with the release
name has an exception for when the release name starts with the chart name.
Therefore the chosen release name must not start with peekabooav, cortex,
mariadb, postfix or rspamd or the assumptions of the main` values.yaml` as well
as those of subcharts such as `cortex-setup` and `peekabooav` about service
names will no longer apply.
They can be overridden from the main `values.yaml`, of course, but a lot of
hassle can be avoided by naming the release carefully.
