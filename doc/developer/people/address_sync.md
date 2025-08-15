# Address Sync

## Overview

It is possible to synchronize addresses with the external [Swiss
Post Service](https://developer.post.ch/en/address-web-services-rest).

The necessary account information must be obtained from Swiss Post directly and
configured in `config/post-address-sync.yml`, see
`config/post-address-sync.example.yml` for details.

Once configured, a button on the top level group appears to allow people with
`:admin` to start the sync. Progress and debugging information is available as
log entries.
