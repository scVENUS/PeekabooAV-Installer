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

Usage
-----

If the pipeline came up successfully, it can be tested by piping a sample into
swaks inside a pod of the `pipeline-postfix-tx` deployment like so:

```bash
cat PATH/TO/OUTSIDE/FILE | kubectl -n pipeline exec -i \
	pipeline-postfix-tx-d677b49f-4r9qh -- sh -c \
	"swaks --server localhost --attach - \
		-t root@pipeline-postfix-rx.pipeline.svc.cluster.local"
```

Note how the email is sent to `root@pipeline-postfix-rx`.

For more practical use, ingress would need to be activated on one of the
postfixes.
We leave that as an exercise to the reader, especially how to make sure, not to
put an open relay on the Net.

`kubectl -n pipeline logs` can then be used to trace the sample's way through
the various systems:

``` shell
kubectl -n pipeline logs pipeline-postfix-tx-d677b49f-4r9qh
[...]
Apr 28 10:06:12 pipeline-postfix-tx postfix/smtp[1467]: AF66FE1541: to=<root@pipeline-postfix-rx.pipeline.svc.cluster.local>, relay=pipeline-postfix-rx.pipeline.svc.cluster.local[10.43.47.60]:25, delay=6.4, delays=0.02/0/0.04/6.4, dsn=4.7.1, status=deferred (host pipeline-postfix-rx.pipeline.svc.cluster.local[10.43.47.60] said: 451 4.7.1 SOFT REJECT - try again later #412 (support-id: C3BA7E2D01-a9d075 (in reply to end of DATA command))
```

Alright, soft rejected by `postfix-rx`.

``` shell
kubectl -n pipeline logs pipeline-postfix-rx-786cb5997-qgjw8
[...]
Apr 28 10:06:12 pipeline-postfix-rx postfix/cleanup[1724]: C3BA7E2D01: milter-reject: END-OF-MESSAGE from 10-42-0-238.pipeline-postfix-tx.pipeline.svc.cluster.local[10.42.0.238]: 4.7.1 SOFT REJECT - try again later #412 (support-id: C3BA7E2D01-a9d075; from=<root@pipeline-po
stfix-tx-d677b49f-4r9qh> to=<root@pipeline-postfix-rx.pipeline.svc.cluster.local> proto=ESMTP helo=<pipeline-postfix-tx.pipeline.svc.cluster.local>
```

Aha, milter-reject. That should've been `rspamd` speaking:

``` shell
kubectl -n pipeline logs pipeline-rspamd-769c54888-b54mb
[...]
2022-04-28 10:06:12 #506(normal) <a9d075>; lua; common.lua:115: peekaboo: result - special scan result set by peekaboo: PEEKABOO_IN_PROCESS: "job_id: 1 - score: 1"
2022-04-28 10:06:12 #506(normal) <a9d075>; task; rspamd_add_passthrough_result: <20220428100605.001724@pipeline-postfix-tx-d677b49f-4r9qh>: set pre-result to 'soft reject' (no score): 'SOFT REJECT - try again later #412 (support-id: C3BA7E2D01-a9d075' from force_actions(0)
2022-04-28 10:06:12 #506(normal) <a9d075>; task; rspamd_task_write_log: id: <20220428100605.001724@pipeline-postfix-tx-d677b49f-4r9qh>, qid: <C3BA7E2D01>, ip: 10.42.0.238, from: <root@pipeline-postfix-tx-d677b49f-4r9qh>, (default: F (soft reject): [0.60/15.00] [MID_RHS_NOT_
FQDN(0.50){},RCVD_NO_TLS_LAST(0.10){},DCC_FAIL(0.00){failed to scan and retransmits exceed;},FORCE_ACTION_PEEKABOO_IN_PROCESS(0.00){soft reject;},FROM_EQ_ENVFROM(0.00){},FROM_NO_DN(0.00){},HAS_ATTACHMENT(0.00){},MID_RHS_MATCH_FROM(0.00){},PEEKABOO_IN_PROCESS(0.00){job_id: 1
;},PREVIOUSLY_DELIVERED(0.00){root@pipeline-postfix-rx.pipeline.svc.cluster.local;},RCPT_COUNT_ONE(0.00){1;},RCVD_COUNT_TWO(0.00){2;},TO_DN_NONE(0.00){},TO_MATCH_ENVRCPT_ALL(0.00){}]), len: 984, time: 6345.174ms, dns req: 0, digest: <9c527d72416542506bcac54c1a252cbc>, rcpts
: <root@pipeline-postfix-rx.pipeline.svc.cluster.local>, mime_rcpts: <root@pipeline-postfix-rx.pipeline.svc.cluster.local>, forced: soft reject "SOFT REJECT - try again later #412 (support-id: C3BA7E2D01-a9d075"; score=nan (set by force_actions)
```

So PeekabooAV was still working on it:

``` shell
kubectl -n pipeline logs pipeline-peekabooav-79575ccdb6-wf7hq
[...]
peekaboo.ruleset.rules - (Worker-0) - DEBUG - 8: Submitting to Cortex
urllib3.connectionpool - (Worker-0) - DEBUG - Starting new HTTP connection (1): pipeline-cortex:9001
urllib3.connectionpool - (Worker-0) - DEBUG - http://pipeline-cortex:9001 "POST /api/analyzer/_search?range=0-1 HTTP/1.1" 200 None
peekaboo.toolbox.cortex - (Worker-0) - DEBUG - Creating Cortex job with analyzer FileInfo_8_0 and parameters {'_json': '{"dataType": "file", "tlp": 2}'}
urllib3.connectionpool - (Worker-0) - DEBUG - http://pipeline-cortex:9001 "POST /api/analyzer/7a2c9fabb22db2625ff95bde8090e7bc/run HTTP/1.1" 200 997
peekaboo.ruleset.rules - (Worker-0) - INFO - 8: Sample submitted to Cortex. Job ID: O0AK1oAB9CxCeV-E5ENa
peekaboo.queuing - (Worker-0) - DEBUG - 8: Report still pending
peekaboo.queuing - (Worker-0) - DEBUG - Worker 0: Ready
urllib3.connectionpool - (CortexJobTracker) - DEBUG - http://pipeline-cortex:9001 "GET /api/job/O0AK1oAB9CxCeV-E5ENa/report HTTP/1.1" 200 1102
peekaboo.server - (MainThread) - DEBUG - No analysis result yet for job 8
```

If submitted again, PeekabooAV should answer from it's cache:

``` shell
kubectl -n pipeline logs pipeline-peekabooav-79575ccdb6-wf7hq
[...]
peekaboo.queuing - (MainThread) - DEBUG - 9: New sample submitted to job queue
peekaboo.queuing - (Worker-2) - INFO - 9: Worker 2: Processing sample
peekaboo.ruleset.engine - (Worker-2) - DEBUG - 9: Processing rule 'known'
peekaboo.sample - (Worker-2) - DEBUG - 9: Adding rule result Result "bad" of rule known - The expression (0) classified the sample as Result.bad, analysis continues: No.
peekaboo.sample - (Worker-2) - DEBUG - 9: Current overall result: Result.unchecked, new rule result: Result.bad
peekaboo.ruleset.engine - (Worker-2) - INFO - 9: Rule 'known' processed
````

... and the message should be rejected:

``` shell
kubectl -n pipeline logs pipeline-rspamd-769c54888-b54mb
[...]
2022-04-28 10:07:12 #507(normal) <b4d2ea>; lua; common.lua:115: peekaboo: result - sandbox threat found: "job-id 9: The expression (0) classified the sample as Result.bad - score: 1"
2022-04-28 10:07:12 #507(normal) <b4d2ea>; task; rspamd_add_passthrough_result: <20220518072150.002529@pipeline-postfix-tx-7bc7f457fd-xckzw>: set pre-result to 'reject' (no score): 'REJECT - Peekaboo said it's bad (support-id: 25B5922CD-b4d2ea)' from force_actions(0)
2022-04-28 10:07:12 #507(normal) <b4d2ea>; task; rspamd_task_write_log: id: <20220518072150.002529@pipeline-postfix-tx-7bc7f457fd-xckzw>, qid: <25B5922CD>, ip: 10.42.2.41, from: <root@pipeline-postfix-tx-7bc7f457fd-xckzw>, (default: T (reject): [4.60/15.00] [PEEKABOO(4.00){
job-id 9: The expression (0) classified the sample as Result.bad;},MID_RHS_NOT_FQDN(0.50){},RCVD_NO_TLS_LAST(0.10){},DCC_FAIL(0.00){failed to scan and retransmits exceed;},FORCE_ACTION_PEEKABOO(0.00){reject;},FROM_EQ_ENVFROM(0.00){},FROM_NO_DN(0.00){},HAS_ATTACHMENT(0.00){}
,MID_RHS_MATCH_FROM(0.00){},PREVIOUSLY_DELIVERED(0.00){root@pipeline-postfix-rx.pipeline.svc.cluster.local;},RCPT_COUNT_ONE(0.00){1;},RCVD_COUNT_TWO(0.00){2;},TO_DN_NONE(0.00){},TO_MATCH_ENVRCPT_ALL(0.00){}]), len: 6715, time: 6052.017ms, dns req: 0, digest: <cfa703779fc970
f6973eb1e6549379bb>, rcpts: <root@pipeline-postfix-rx.pipeline.svc.cluster.local>, mime_rcpts: <root@pipeline-postfix-rx.pipeline.svc.cluster.local>, forced: reject "REJECT - Peekaboo said it's bad (support-id: 25B5922CD-b4d2ea)"; score=nan (set by force_actions)
2022-04-28 10:07:12 #507(normal) <b4d2ea>; task; rspamd_protocol_http_reply: regexp statistics: 0 pcre regexps scanned, 0 regexps matched, 0 regexps total, 0 regexps cached, 0B scanned using pcre, 0B scanned total
```
