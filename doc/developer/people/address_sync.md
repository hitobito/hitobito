# Address Sync

## Overview

It is possible to synchronize addresses with the external [Swiss
Post Service](https://developer.post.ch/en/address-web-services-rest).

The necessary account information must be obtained from Swiss Post directly. The
configuration is placed in `config/post-address-sync.yml`, see
`config/post-address-sync.example.yml` for details.

Additionally, you have to enable the sync by `Settings.address_sync.enabled` to
true.

Once configured and enabled, a button on the top level group appears which
allows people with `:admin` to start the sync. Progress and debugging
information is available as log entries.

## QSTAT Codes

Swiss Post returns a status code (QSTAT) for each person in the result file.
See the [Swiss Post QSTAT documentation](https://www.post.ch/-/media/portal-opp/pm/dokumente/merkblatt-status-qstat-shortreport.pdf?sc_lang=de&hash=ABCBEDD36A9D36BE68B0ACCAFAED702B) for the full reference.

If a person gets one of the LOGGINGS_QSTATS, a log entry will be created and the person receives a tag with the corresponding QSTAT code and a timestamp.

## Excluded Tags

Wagons can configure a list of tags that mark people as excluded from future sync runs. These tags are configured in `config/post-address-sync.yml`

When a person's address fields are manually updated, these excluded tags are automatically removed, showing that the address is fresh and the person should be included in the next sync again.
