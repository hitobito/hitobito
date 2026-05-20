# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About

PuzzleTime is a Ruby on Rails 7.0 time-tracking and resource-planning web application. It supports multiple authentication backends (DB, LDAP, SAML, Keycloak, OAuth) and integrates with Highrise CRM and SmallInvoice for billing.

## Development Setup

```bash
docker-compose up -d        # Start PostgreSQL (and optionally Memcached, MailCatcher)
bin/setup                   # Install gems, prepare DB, clear logs
rails server                # Start dev server
```

Default seed users (password `a` for all): MW, AR, PZ, DI.
Set `AUTH_DB_ACTIVE=true` to use standard DB authentication in development.

## Common Commands

```bash
rake                                    # Run full test suite (unit + integration)
rake test TEST=test/path/to/file.rb     # Run a single test file
rake test TEST=test/path/to/file.rb:42  # Run test at a specific line
rake jobs:work                          # Process background jobs (Delayed Job)

rubocop                                 # Lint Ruby
rubocop --autocorrect                   # Auto-fix offenses
haml-lint app/views                     # Lint HAML templates
brakeman                                # Security scan
bundler-audit                           # Gem vulnerability audit
rake erd                                # Regenerate Entity Relationship Diagram
rake annotate                           # Update schema annotations on models
```

Integration tests use Capybara + Cuprite (headless Chrome). Set `HEADLESS=false` to show the browser. Overcommit runs pre-commit hooks (RuboCop, HAML-Lint, BundleAudit).

Append `?profile_request=true` to any URL to profile a single request in development.

## Architecture

### Domain Model

Time entries use Single Table Inheritance under `Worktime`:
- `Ordertime` — time booked against work items
- `Absencetime` — absences/vacation

Work items form a three-level hierarchy: **Client → Order → AccountingPost**. `WorkItem` is the shared base using a nested-set/adjacency tree.

Other central models: `Employee`, `Planning` (resource allocation), `Invoice`, `Employment`, `Department`, `Holiday`, `Expense`.

### Business Logic (`app/domain/`)

Domain services live outside `app/models/` to keep models thin:

| Directory | Responsibility |
|---|---|
| `billing/` | SmallInvoice sync (two-way) |
| `crm/` | Highrise CRM sync (one-way import) |
| `invoicing/` | Invoice generation and management |
| `order/` | Order status, cockpit logic |
| `plannings/` | Scheduling calculations |
| `evaluations/`, `reports/`, `graphs/` | Reporting and data aggregation |

### API

A JSON:API endpoint lives at `/api/v1/` (FastJsonapi). OpenAPI docs are generated via rswag (`rake rswag:specs:swaggerize`).

### Authorization

CanCanCan abilities are defined in `app/models/ability.rb`. Devise handles authentication sessions; OmniAuth callbacks handle SSO providers.

### Background Jobs

Delayed Job with `delayed_cron_job` for scheduled tasks. Jobs are defined in `app/jobs/`. Run `rake jobs:work` locally.

### Frontend

HAML views, Bootstrap-Sass, jQuery, Turbolinks. No modern JS bundler — assets go through the Rails asset pipeline (Sprockets).

### Testing

Minitest throughout. Integration tests use Capybara with Cuprite (headless Chrome). Factories are in `test/factories/`. CI runs on GitHub Actions with PostgreSQL 11 and Memcached.
