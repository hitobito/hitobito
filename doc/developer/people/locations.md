# Locations

## Overview

In the database, there is a mapping from Swiss Zip-Codes to Town and Canton.
This is stored in the locations-table.

During seeding, a provided CSV is imported. Any preexisting locations are
cleaned before. The locations are only seeded once, but there is an
"Update Procedure".

## Update-procedure

* Get the file manually from https://www.post.ch/de/pages/downloadcenter-match
* Strip all unneeded rows and columns.
  **BEWARE**: There are two zip_code columns, only one contains 3006!
* Add a header for zip_code, town and canton
* Save with separator ; encoded as UTF-8
  (Libre Office: Save as -> Edit Filter Settings)
* Store the file as `db/seeds/support/locations.csv`
* `rails db:remove_seed_markers db:seed` to load the new CSV.

## How and why reseeding is complicated but scripted

Since seeding truncates the table a successful seeding is remembered in the
database. This is needed because truncation in MySQL drops and recreates the
table. Also, reseeding without a changed data-source does not make sense. In
order to remove the "is seeded"-marker, the above mentioned rake-take present.

The "seeded"-marker is stored in the table `ar_internal_metadata`, which is
present since Rails 5. It is indeed an internal feature, but fits right now.
