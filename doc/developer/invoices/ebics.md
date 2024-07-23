# Ebics

## Overview

It is possible to receive invoice payment data from a specified bank using the [Ebics Standard](https://www.ebics.org/en/home)

## Gem

The implementation uses the [Epics Gem](https://github.com/railslove/epics).

The Gem gets wrapped inside the `app/domain/payment_provider.rb` class.

## Configuring bank parameters

### Settings

To setup the bank connection, the payment provider (= bank) needs to be registered inside `config/settings.yml`

The key `payment_providers` contains an array, where payment providers can be inserted as hashes with the following keys:

- name (label of the provider)
- url (https endpoint for ebics requests)
- host_id (identificator of the provider)
- encryption_hash (providers hashed public key for encryption)
- authentication_hash (providers hashed public key for authentication)

The keys `url, host_id, encryption_hash, authentication_hash` will be given by the provider.

### InvoiceConfig

Inside the invoice config form there is a tab for the PaymentProviderConfigs to be configured.

These require the `partner_identifier, user_identifier & password` fields to be filled.

After submitting, hitobito will try to establish a connection to the payment provider using the INI & HIA order types. (See `app/controllers/invoice_configs_controller.rb`)

The ini letter is then accessible from the show page of the invoice config.

### Used order types

These are the order types implemented by the `app/domain/payment_provider.rb` class:

- INI (initializes the ebics connection)
- HIA (submits certificates to establish transactions)
- HPB (receives bank public keys and matches them to encryption_hash & authentication_hash in `config/settings.yml`)
- XTC (uploads csv data)
- Z54 (receives invoice payment data in camt.54 format)

IMPORTANT: The order types have to be supported by the payment provider to work!

### Bank public keys change

When the bank changes their public keys, the HPB request will fail and throw a `PaymentProviders::EbicsError` error.

At this point, check the `encryption_hash` and `authentication_hash` values in the Settings and whether they're still up to date.

## Exporting payments

### Rake Tasks

There are two rake tasks for exporting payments. Used when importing payments via EBICS:

`rake payment:export_without_invoice`: Exports payments without assigned invoice
`rake payment:export_ebics_imported`: Exports payments that were imported via EBICS

#### Usage

Both these tasks have optional arguments for the start and end date of the export.

E.g `rake payment:export_without_invoice[2022.01.01,2022.12.01]`

**Default**: from: `1.month.ago` to: `Time.zone.today`
