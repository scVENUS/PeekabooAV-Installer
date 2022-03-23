## Usage
To boot up the pipeline, you can simply use
```bash
docker-compose up -d
```

### Logs
First of all, it's a good idea to keep an eye on the logs. If you started the pipeline detached, you can execute
```bash
docker-compose logs -f
```
to follow all logs, or
```bash
docker-compose logs postfix_rx -f
```
to follow the logs from the container that receives the emails.

### Sending emails

The postfix_tx conainer is set up to relay emails to the rx container.

To use it that way, you can use a tool like [SWAKS](https://jetmore.org/john/code/swaks/)
```bash
cat DemoMalware/downloadexe.bat | swaks --server localhost:8025 --to root@localhost --attach -
```
Above command sends and email, with the supplied `downloadexe.bat` file as an
attachment[^attachfileat], to the postfix\_tx container.
Which then relays this email to the postfix\_rx container and takes care of Soft
Rejects, etc.

[^attachfileat]: `--attach` can take the file name directly as well but has
  recently switched to supporting and will later switch to requiring an `@` in
  front of the file name to indicate that case similar to curl.
  Because of missing support for the notation, earlier versions will attach the
  file name as a string including the `@` instead.
  Make sure you get the behaviour you want from your version of swaks, e.g. by
  verifying what's attached using `--dump-mail`.

If you are unable to use a tool like SWAKS, you can send an email from inside of the postfix_tx container directly. To get a shell inside the postfix_tx container use:
```bash
docker-compose exec postfix_tx sh
```
Inside you can send emails the same way by sending them to `localhost:25`
```bash
swaks --server localhost -t root@postfix_tx --attach @PATH/TO/FILE
```
(swaks in the `postfix_tx` container is current enough to support the new `@` syntax.)

Combining both commands, content can also be supplied from the outside to swaks
running inside the container:
```bash
cat PATH/TO/OUTSIDE/FILE | docker-compose exec -T postfix_tx swaks --server localhost -t root@postfix_tx --attach -
```
(Note the `-T` to `docker-compose exec`.)

### Post-Send

In the logs of postfix_rx you can now see what happened to the email.

Most likely you will see someting similar to the following
```
postfix_rx postfix/cleanup[82]: B37FF5BE9A: milter-reject: END-OF-MESSAGE from peekabooav-installer-clean-postfix_tx-1.peekabooav-installer-clean_default[172.22.0.3]: 4.7.1 SOFT REJECT - try again later #412 (support-id: B37FF5BE9A-0d8933; from=<root@postfix_tx> to=<root@postfix_rx> proto=ESMTP helo=<postfix_tx>
```
This means that the email was soft rejected and the transmitting server should send the email again in a while. If you do not wish to wait for the postfix in the tx container to automatically do this, you can flush the queue manually by running
```bash
docker-compose exec postfix_tx postfix flush
```
*NOTE: A Soft Reject **should** only be authored if the corresponding Peekaboo job is in process. To confirm this, you can look for the symbol `PEEKABOO_IN_PROCESS` in the rspamd logs*

If the email is received again, and peekaboo has a result ready, there are two possibilities.
Either the email is fully rejected, which would look similar to this
```
postfix_rx postfix/cleanup[82]: 2CCCC5BDC2: milter-reject: END-OF-MESSAGE from peekabooav-installer-clean-postfix_tx-1.peekabooav-installer-clean_default[172.22.0.3]: 5.7.1 REJECT - Peekaboo said it's bad (support-id: 2CCCC5BDC2-66963d); from=<root@postfix_tx> to=<root@postfix_rx> proto=ESMTP helo=<postfix_tx>
```

Or it could have been delivered:
```
postfix_rx postfix/local[84]: D029B5BE61: to=<root@localhost>, orig_to=<root@postfix_rx>, relay=local, delay=0.04, delays=0.03/0.01/0/0, dsn=2.0.0, status=sent (delivered to mailbox)
```
which should only happen with emails that are not classified as bad by peekaboo.
