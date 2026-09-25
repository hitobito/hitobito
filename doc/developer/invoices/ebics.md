# Ebics

## Overview

It is possible to receive invoice payment data from a specified bank using the [Ebics Standard](https://www.ebics.org/en/home)

## Gem

The implementation uses the [Epics Gem](https://github.com/railslove/epics).

The Gem gets wrapped inside the `app/domain/payment_provider.rb` class.

## Configuring bank parameters

### Settings

To setup the bank connection, the payment provider (= bank) needs to be registered inside `config/settings/payment_providers.yml` and the label must be translated under the key `de.activerecord.attributes.payment_provider_config.payment_providers.#{bank}`.

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

## Importing payments

### Jobs

The Import is done via two Jobs
- `Payments::EbicsImportScheduleJob`: RecurringJob running every morning at 08:00. Schedules the `Payments::EbicsImportJob` per initialized `PaymentProviderConfig`
- `Payments::EbicsImportJob`: Runs the import of all payments for its provided `PaymentProviderConfig`

### Logging

The `Payments::EbicsImportJob` takes care of logging the payment import events. All errors are being logged to Sentry and in addition there are certain events that will be logged to `HitobitoLogEntry`:
1. The start of the payment import process
2. The successful import of payments
3. Errors and exceptions. If possible, it will attach the payment camt.54 XML to the `HitobitoLogEntry#attachment`.

## Exporting payments

### Rake Tasks

There are two rake tasks for exporting payments. Used when importing payments via EBICS:

`rake payment:export_without_invoice`: Exports payments without assigned invoice
`rake payment:export_ebics_imported`: Exports payments that were imported via EBICS

#### Usage

Both these tasks have optional arguments for the start and end date of the export.

E.g `rake payment:export_without_invoice[2022.01.01,2022.12.01]`

**Default**: from: `1.month.ago` to: `Time.zone.today`

## Development and Testing via Test Platforms

For development we use certain test platforms. These are configured payment_providers under settings/development.yml.

### Hooking up your local Hitobito to a Test Platform

1. Log in to the bank test platforms website on the url found in the payment_provider yml
2. Navigate to the EBICS Settings and reset the EBICS client ( EBICS-Teilnehmer zurücksetzen )
3. Go into your Hitobito and fill out the PaymentProviderConfig in the form with the given Kunden-ID, Teilnehmer-ID and a random password
4. When saving the form, Hitobito should show a success flash message to indicate that both the INI and HIA requests worked.
5. In the bank test platform on the same page as before, unlock your EBICS client ( EBICS-Teilnehmer freischalten )
6. Now you can either manually trigger the `EbicsImportScheduleJob` or use the rails console to grab a `PaymentProvider` instance of that PaymentProviderConfig. Either way once you ran the `PaymentProvider#HPB` method (and it returns `true`) the client is successfully connected

### Up & Downloading payment data to the Test Platform

**IN ORDER TO DOWNLOAD camt.054 DATA USING THE EBICS CLIENT ON TEST PLATFORMS YOU HAVE TO UPLOAD THEM VIA THE EBICS CLIENT**

1. Open your rails console
2. Get your config: `config = PaymentProviderConfig.find(my_config_for_testing)`
3. Create a provider: `provider = PaymentProvider.new(config)`
4. Get a valid CSV for QRR payments, there is one for postfinance in the spec fixtures: `csv = File.read(Rails.root.join("spec", "fixtures", "invoices", "postfinance_payment_upload.csv"))`
5. Authorize your client: `provider.HPB`
6. Upload the CSV: `provider.XTC(csv)`
7. Download the resulting camt.054: `provider.Z54(3.days.ago, 1.day.from_now)`

The same CSV should be uploadable multiple times. When successful you should also find it on the Platforms Web UI and the Platforms often provide `Best-Practice-Dateien` found in the upper right corner of the Web UI

