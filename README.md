# Puppet reporter for Sentry

This Puppet module sends reports about failed runs to <https://sentry.io/>.

You'll need the `sentry-raven` gem installed on the Puppet master.

## Setting the Sentry DSN

The `sentry-raven` Gem should automatically detect the DSN from the `SENTRY_DSN`
environment variable. This is the default behaviour of `sentry-raven`.

Older versions of Puppet Server don't allow custom environment variables to be
set. In this case, setting the DSN from `/etc/puppet/sentry.conf` is also
supported. The contents of the file should be:

```
dsn = https://USER:PASS@sentry.io/123456/
```

The environment variable `PUPPET_SENTRY_DSN` is also checked.

If a DSN can't be found, the reporter is not registered, and an error is logged
to the Puppet Server's logfile.

