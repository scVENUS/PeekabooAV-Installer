# Utils #

These tools help!

# Manual Checks #

   - Check paths to the peekaboo socket file in the amavis and peekaboo configuration
   - Try to connect via smtp to amavis (127.0.0.1:10024) and hand in your message there
   - Check local mail delivery and try again

This way you test every step in the process and verify its correct and functional.


# checkFileWithPeekaboo.py #

Connects via `SMTP` to e.g. Postfix or directly to amavis.


# dropPeekabooTables.sh #

Clears Peekaboo Tables in mysql.
Don't run if you don't mean it.


# peekabooStatus.sh #

This script outputs information on how you installation is running.
It collects information from `systemd`, `postfix` ...

Helps a lot in debugging. We might ask you to run it so we can better help.

# repoFileIntegrity.sh #

Is mostly for me quickly find changes I made and update the installer.
