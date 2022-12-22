## JSON:API

This documentation is about the new JSON API introduced in 2023. Check the [legacy Api documentation](05_rest_api.md) for the old Api.

The hitobito JSON:API implements the open standard **[json:api](https://jsonapi.org) v1.1** with media type **[application/vnd.api+json](http://www.iana.org/assignments/media-types/application/vnd.api+json)**

### Endpoints

Currently the following endpoints are provided:

| Method | Path                                              | Function                                                                        |
| ---    | ---                                               | ---                                                                             |
| GET    | /api/people/                                      | List all accessible people                                                      |
| GET    | /api/people/:id                                   | Fetch a single person entry, replace :id with the person's primary key          |
| PATCH  | /api/people/:id                                   | Update a person entry, replace :id with the person's primary key                |

Visit your hitobito's swagger UI [/api-docs](/api-docs) for detailed documentation and a sandbox for testing/developing requests.

All successful responses do have HTTP Status `2xx`.

To protect from CSRF attacks, requests must have set **Content-Type** header to **application/vnd.api+json**.

### Errors

Any error like authentication or validation errors are rendered as JSON as defined by the [json:api](https://jsonapi.org/format/#errors) standard.  Also a specific http status code is being returned for any errors.

Error example: trying to access a person without propper permission:

GET /api/people/42

HTTP Status 403 - Forbidden

```json
{"errors":
  [{"code":"forbidden",
    "status":"403",
    "title":"Access denied",
    "detail":"Du bist nicht berechtigt auf diese Resource zuzugreifen.",
    "meta":{}}
  ]
}
```

the error's field detail is translated by provided locale. all other fields are in English.

### Authentication

To use the API you need a valid authentication token, this can be one of the following

* Service tokens
* Personal OAuth access tokens
* Active user session

#### Service token

Service tokens are impersonal tokens ([service accounts](07_service_accounts.md)), that are meant to represent external applications.

> :bangbang: Service tokens allow you to implement user unaware applications. Note that the
consumer application is responsible for data protection: with service tokens the application
may be able to access data which is not intended for public access!

#### Personal OAuth access token

Personal OAuth access tokens have the same permissions as the corresponding user, this allows you
to implement an application where users log in using Hitobito as an OAuth authentication provider.

To use the API, the provided access token is required to have the `api` scope, see [OAuth](08_oauth.md) for more information.

#### Active user session

For development purposes or async requests, the API can also be accessed with the current user web session. Just login as user and then visit any `/api` endpoints or use [Swagger](/api-docs).

### Example Requests

#### GET people changed after a certain date/time

* filter[updated_at]: 2022-12-20+00:52:09
* include Phone Numbers

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

### Hitobito Developer

Checklist for creating/extending JSON:API endpoints:

- Add/extend swagger specs in `specs/requests/json_api/`
  - create/extend model schema for swagger (e.g. specs/requests/json_api/person_schema.rb)
  - create/extend request spec
  - run `rails rswag:specs:swaggerize` afterwards and check if Swagger ui is working as expected
- Update list of endpoints in this document
