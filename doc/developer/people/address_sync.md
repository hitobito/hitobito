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
