## JSON:API


The hitobito JSON:API implements the open standard [json:api](https://jsonapi.org) v1.1 with media type [application/vnd.api+json](http://www.iana.org/assignments/media-types/application/vnd.api+json).

Visit your hitobito's [Swagger UI](/api-docs) for detailed documentation and a sandbox for testing/developing requests. (Reload if you get a blank page on the first visit).

This documentation is about the new JSON API introduced in 2023. Check the [legacy Api documentation](/doc/developer/common/api/rest_api.md) for the old Api.

### Endpoints

Currently the following endpoints are provided:

| Method | Path                           | Function                                                                     |
|--------|--------------------------------|------------------------------------------------------------------------------|
| GET    | /api/people/                   | List all accessible people                                                   |
| GET    | /api/people/:id                | Fetch a single person entry, replace :id with the person's primary key       |
| PATCH  | /api/people/:id                | Update a person entry, replace :id with the person's primary key             |
| GET    | /api/roles/                    | List all accessible roles                                                    |
| POST   | /api/roles/                    | Create a new role                                                            |
| GET    | /api/roles/:id                 | Fetch a single role entry, replace :id with the roles' primary key           |
| PATCH  | /api/roles/:id                 | Update a role entry, replace :id with the roles' primary key                 |
| DELETE | /api/roles/:id                 | Remove a role entry, replace :id with the roles' primary key                 |
| GET    | /api/groups/                   | List all accessible groups                                                   |
| GET    | /api/groups/:id                | Fetch a single group entry, replace :id with the groups's primary key        |
| GET    | /api/events/                   | List all accessible events                                                   |
| GET    | /api/events/:id                | Fetch a single event entry, replace :id with the event's primary key         |
| GET    | /api/event_kinds/              | List all accessible events kinds                                             |
| GET    | /api/event_kinds/:id           | Fetch a single event kind, replace :id with the event's primary key          |
| GET    | /api/event_kind_categories/    | List all accessible events kind categories                                   |
| GET    | /api/event_kind_categories/:id | Fetch a single event kind category, replace :id with the event's primary key |


All successful responses do have HTTP Status `2xx`.

To protect from CSRF attacks, requests must have set **Content-Type** header to **application/vnd.api+json**.

### Errors

Any error like authentication or validation errors are rendered as JSON as defined by the [json:api](https://jsonapi.org/format/#errors) standard. Also a specific http status code is being returned for any errors.

Error example: trying to access a person without propper permission:

GET /api/people/42

HTTP Status 403 - Forbidden

```json
{
  "errors": [
    {
      "code": "forbidden",
      "status": "403",
      "title": "Access denied",
      "detail": "Du bist nicht berechtigt auf diese Resource zuzugreifen.",
      "meta": {}
    }
  ]
}
```

the error's field detail is translated by provided locale. all other fields are in English.

### Authentication

To use the API you need a valid authentication token, this can be one of the following

- Service tokens
- Personal OAuth access tokens
- Active user session

#### i18n / globalization

To retrieve localized responses for fields that are translated with [globalize](https://github.com/globalize/globalize) you can set the `locale`query parameter to the desired locale.

```curl
curl \
  'http://hitobito.example.com/api/event_kinds/1?locale=fr' \
  -H 'accept: */*' \
  -H 'X-TOKEN: u-j3QQoPoSg8pwwgqe3W9CMVPVPFCFykFK2A2VCSq1BzznDuUA' \
  -H 'Content-Type: application/vnd.api+json'
```

```json
{
  "data": {
    "id": "1",
    "type": "event_kinds",
    "attributes": {
      "label": "Cours de coach",
      "short_name": "",
      "general_information": null,
      "application_conditions": null,
      "minimum_age": 18,
      "created_at": "2025-03-21T22:13:02+01:00",
      "updated_at": "2025-03-23T12:30:16+01:00"
    },
    "relationships": {
      "kind_category": {
        "meta": {
          "included": false
        }
      }
    }
  },
  "meta": {}
}
```

#### Service token

Service tokens are impersonal tokens ([service accounts](/doc/developer/common/api/service_accounts.md)), that are meant to represent external applications.

> :bangbang: Service tokens allow you to implement user unaware applications. Note that the
> consumer application is responsible for data protection: with service tokens the application
> may be able to access data which is not intended for public access!

#### Personal OAuth access token

Personal OAuth access tokens have the same permissions as the corresponding user, this allows you
to implement an application where users log in using Hitobito as an OAuth authentication provider.

To use the API, the provided access token is required to have the `api` scope, see [OAuth](/doc/developer/people/oauth.md) for more information.

#### Active user session

For development purposes or async requests, the API can also be accessed with the current user web session. Just login as user and then visit any `/api` endpoints.

### Example Requests

#### GET people changed after a certain date/time

- filter[updated_at]: 2022-12-20+00:52:09
- include Phone Numbers

Request

```curl
curl -X 'GET' \
  'http://hitobito.example.com/api/people?include=phone_numbers,&filter%5Bupdated_at%5D=2022-12-20%2B00%3A52%3A09' \
  -H 'accept: */*' \
  -H 'X-TOKEN: u-j3QQoPoSg8pwwgqe3W9CMVPVPFCFykFK2A2VCSq1BzznDuUA'
```

Response **200 OK**

```json
{
  "data": [
    {
      "id": "48",
      "type": "people",
      "attributes": {
        "first_name": "Tobias",
        "last_name": "Meyer",
        "nickname": null,
        "company_name": null,
        "company": false,
        "email": "meyer@example.com",
        "address": null,
        "zip_code": "",
        "town": null,
        "country": "CH",
        "gender": null,
        "birthday": null,
        "primary_group_id": 1
      },
      "relationships": {
        "phone_numbers": {
          "data": [
            {
              "type": "phone_numbers",
              "id": "73"
            }
          ]
        },
        "social_accounts": {
          "meta": {
            "included": false
          }
        },
        "additional_emails": {
          "meta": {
            "included": false
          }
        },
        "roles": {
          "meta": {
            "included": false
          }
        }
      }
    }
  ],
  "included": [
    {
      "id": "73",
      "type": "phone_numbers",
      "attributes": {
        "label": "Privat",
        "public": true,
        "contactable_id": 48,
        "contactable_type": "Person",
        "number": "+41 79 710 77 77"
      },
      "relationships": {
        "contactable": {
          "meta": {
            "included": false
          }
        }
      }
    }
  ],
  "meta": {}
}
```

#### PATCH person

Request

```curl
curl -X 'PATCH' \
  'http://hitobito.example.com/api/people/48' \
  -H 'accept: */*' \
  -H 'X-TOKEN: u-j3QQoPoSg8pwwgqe3W9CMVPVPFCFykFK2A2VCSq1BzznDuUA' \
  -H 'Content-Type: application/vnd.api+json' \
  -d '{
  "data": {
    "id": "48",
    "type": "people",
    "attributes": {
      "first_name": "Tobias",
      "last_name": "Meyer"
    },
    "relationships": {
      "phone_numbers": {
        "data": [
          {
            "type": "phone_numbers",
            "id": "73",
            "method": "update"
          }
        ]
      }
    }
  },
  "included": [
    {
      "type": "phone_numbers",
      "id": "73",
      "attributes": {
        "number": "0797335842"
      }
    }
  ]
}'
```

Response **200 OK**

```json
{
  "data": {
    "id": "48",
    "type": "people",
    "attributes": {
      "first_name": "Tobias",
      "last_name": "Meyer",
      "nickname": null,
      "company_name": null,
      "company": false,
      "email": "meyer@example.com",
      "address": null,
      "zip_code": "",
      "town": null,
      "country": "CH",
      "gender": null,
      "birthday": null,
      "primary_group_id": 1
    },
    "relationships": {
      "phone_numbers": {
        "data": [
          {
            "type": "phone_numbers",
            "id": "73"
          }
        ]
      },
      "social_accounts": {
        "meta": {
          "included": false
        }
      },
      "additional_emails": {
        "meta": {
          "included": false
        }
      },
      "roles": {
        "meta": {
          "included": false
        }
      }
    }
  },
  "included": [
    {
      "id": "73",
      "type": "phone_numbers",
      "attributes": {
        "label": "Privat",
        "public": true,
        "contactable_id": 48,
        "contactable_type": "Person",
        "number": "+41 79 733 58 42"
      }
    }
  ],
  "meta": {}
}
```

### ServiceToken Permission

The following table shows required Service Token permissions per endpoint.

| Endpoint | required permission |
| -------- | ------------------- |
| /people  | people              |
| /groups  | groups              |
| /roles   | groups, people      |
| /events  | events              |

### Hitobito Developer

Checklist for creating/extending JSON:API endpoints:

- Add/extend resource in `app/resources/` and for endpoint changes also in `app/controllers/json_api/`
- Add/extend tests
  - for new resources, generate tests with `rails generate graphiti:resource_test <ResourceClass>`
  - for new endpoints, generate tests with `rails generate graphiti:api_test <ResourceClass>`
- Add/extend ability in `app/abilities/json_api/`
- Run `rake graphiti:schema:generate` where you did the changes (core/wagon) to update
  the schema file and add it to git
- Update list of endpoints in this document

#### Permissions

Permissions are primarly checked in graphiti resources `app/resources`, not in controllers like
in non JSON:API controllers. For this there's specific abilities in `app/abilities/json_api`.
We're also authorizing inside the JSON:API controllers to make sure
the right HTTP status code is returned. (e.g. 403 instead of 404 if access denied)
