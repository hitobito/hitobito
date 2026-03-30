## JSON:API


The hitobito JSON:API implements the open standard [json:api](https://jsonapi.org) v1.1 with media type [application/vnd.api+json](http://www.iana.org/assignments/media-types/application/vnd.api+json).

Visit your hitobito's Swagger UI at _your-hitobito-url_[/api-docs](/api-docs) for detailed documentation and a sandbox for testing/developing requests. (Reload if you get a blank page on the first visit).

This documentation is about the new JSON API introduced in 2023. Check the [legacy Api documentation](/doc/developer/common/api/rest_api.md) for the old, deprecated Api.

### Endpoints

Currently the following endpoints are provided:

| Method | Path                               | Function                                                                                |
|--------|------------------------------------|-----------------------------------------------------------------------------------------|
| GET    | /api/people/                       | List all accessible people                                                              |
| GET    | /api/people/:id                    | Fetch a single person entry, replace :id with the person's primary key                  |
| PUT    | /api/people/:id                    | Update a person entry, replace :id with the person's primary key                        |
| GET    | /api/roles/                        | List all accessible roles                                                               |
| POST   | /api/roles/                        | Create a new role                                                                       |
| GET    | /api/roles/:id                     | Fetch a single role entry, replace :id with the roles' primary key                      |
| PUT    | /api/roles/:id                     | Update a role entry, replace :id with the roles' primary key                            |
| DELETE | /api/roles/:id                     | Remove a role entry, replace :id with the roles' primary key                            |
| GET    | /api/groups/                       | List all accessible groups                                                              |
| GET    | /api/groups/:id                    | Fetch a single group entry, replace :id with the groups's primary key                   |
| GET    | /api/events/                       | List all accessible events                                                              |
| GET    | /api/events/:id                    | Fetch a single event entry, replace :id with the event's primary key                    |
| GET    | /api/event_participations/         | List all accessible event participations                                                |
| GET    | /api/event_participations/:id      | Fetch a single event particiation entry, replace :id with the event's primary key       |
| GET    | /api/event_kinds/                  | List all accessible events kinds                                                        |
| GET    | /api/event_kinds/:id               | Fetch a single event kind, replace :id with the event's primary key                     |
| GET    | /api/event_kind_categories/        | List all accessible events kind categories                                              |
| GET    | /api/event_kind_categories/:id     | Fetch a single event kind category, replace :id with the event's primary key            |
| GET    | /api/invoices/                     | List all accessible invoices                                                            |
| GET    | /api/invoices/:id                  | Fetch a single invoice, replace :id with the invoice's primary key                      |
| PUT    | /api/invoices/:id                  | Update an invoice, replace :id with the list's primary key                              |
| GET    | /api/mailing_lists/                | List all accessible mailing lists                                                       |
| GET    | /api/mailing_lists/:id             | Fetch a single mailing_list, replace :id with the list's primary key                    |
| GET    | /api/groups/:id/self_registrations | Create a new person in a group that allows it, replace :id with the group's primary key |


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

To retrieve localized responses for fields that are translated with [globalize](https://github.com/globalize/globalize) you can set the `locale` query parameter to the desired locale.

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

#### PUT person

Request

```curl
curl -X 'PUT' \
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

Response **201 Created**

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

#### POST self_registrations - register a new person

Pre-requisites:
- The group must accept self registrations (can be activated on the group)
- The service token needs register_people and write permissions
- The exact fields required such as company_name, adult_consent and privacy_policy_accepted may vary depending on the group, group hierarchy and hitobito instance

Request

```curl
curl -X 'POST' \
  'http://hitobito.example.com/api/groups/123/self_registrations' \
  -H 'accept: */*' \
  -H 'X-TOKEN: u-j3QQoPoSg8pwwgqe3W9CMVPVPFCFykFK2A2VCSq1BzznDuUA' \
  -H 'Content-Type: application/vnd.api+json' \
  -d '{
  "data": {
    "type": "self_registrations",
    "attributes": {
      "first_name": "Tom",
      "last_name": "Tester",
      "company_name": "nobody",
      "nickname": "Jerry",
      "company": true,
      "email": "test@email.com",
      "adult_consent": true,
      "privacy_policy_accepted": true
    }
  }
}'
```

Response **201 Created**

```json

{
  "data": {
    "id": "5089",
    "type": "self_registrations",
    "attributes": {
      "first_name": "Tom",
      "last_name": "Tester",
      "nickname": "Jerry",
      "company_name": "nobody",
      "company": true,
      "email": "test@email.com",
      "privacy_policy_accepted": true
    }
  },
  "links": {
    "self": "/api/groups/123/self_registrations?data%5Battributes%5D%5Badult_consent%5D=true&data%5Battributes%5D%5Bcompany%5D=true&data%5Battributes%5D%5Bcompany_name%5D=nobody&data%5Battributes%5D%5Bemail%5D=test%40email.com&data%5Battributes%5D%5Bfirst_name%5D=Tom&data%5Battributes%5D%5Blast_name%5D=Tester&data%5Battributes%5D%5Bnickname%5D=Jerry&data%5Battributes%5D%5Bprivacy_policy_accepted%5D=true&data%5Btype%5D=self_registrations&page%5Bnumber%5D=1&page%5Bsize%5D=20",
    "first": "/api/groups/123/self_registrations?data%5Battributes%5D%5Badult_consent%5D=true&data%5Battributes%5D%5Bcompany%5D=true&data%5Battributes%5D%5Bcompany_name%5D=nobody&data%5Battributes%5D%5Bemail%5D=test%40email.com&data%5Battributes%5D%5Bfirst_name%5D=Tom&data%5Battributes%5D%5Blast_name%5D=Tester&data%5Battributes%5D%5Bnickname%5D=Jerry&data%5Battributes%5D%5Bprivacy_policy_accepted%5D=true&data%5Btype%5D=self_registrations&page%5Bnumber%5D=1&page%5Bsize%5D=20",
    "last": "/api/groups/123/self_registrations?data%5Battributes%5D%5Badult_consent%5D=true&data%5Battributes%5D%5Bcompany%5D=true&data%5Battributes%5D%5Bcompany_name%5D=nobody&data%5Battributes%5D%5Bemail%5D=test%40email.com&data%5Battributes%5D%5Bfirst_name%5D=Tom&data%5Battributes%5D%5Blast_name%5D=Tester&data%5Battributes%5D%5Bnickname%5D=Jerry&data%5Battributes%5D%5Bprivacy_policy_accepted%5D=true&data%5Btype%5D=self_registrations&page%5Bnumber%5D=&page%5Bsize%5D=20"
  },
  "meta": {}
}
```

### ServiceToken Permission

The following table shows required Service Token permissions per endpoint.

| Endpoint                        | required permission                |
|---------------------------------|------------------------------------|
| /people                         | people                             |
| /groups                         | groups                             |
| /roles                          | groups, people                     |
| /invoices                       | invoices                           |
| /events                         | events                             |
| /event_participations           | event_participations               |
| /event_kinds                    | events                             |
| /event_kind_categories          | events                             |
| /mailing_lists                  | mailing_lists                      |
| /groups/{id}/self_registrations | register_people + write permission |

### Hitobito Developer

Checklist for creating/extending JSON:API endpoints:

- Add/extend resource in `app/resources/` and for endpoint changes also in `app/controllers/json_api/`
- Add/extend tests
  - for new resources, generate tests with `rails generate graphiti:resource_test <ResourceClass>`
  - for new endpoints, generate tests with `rails generate graphiti:api_test <ResourceClass>`
- Add/extend ability in `app/abilities/json_api/`
  - ability must only use [hash syntax](https://github.com/CanCanCommunity/cancancan/blob/develop/docs/fetching_records.md) so that it can be used for database querying with `Model.accessible_by`
  - ability must work even when `user.id == nil` (in the case of service tokens; simply don't grant access to things that require a user id)
  - on the resource, declare the ability class in `self.readable_class`, and configure which token scopes are required for accessing the resource in `self.acceptable_scopes`
  - see `JsonApi::EventParticipationAbility` and `Event::ParticipationResource` for an example
- Run `rake graphiti:schema:generate` where you did the changes (core/wagon) to update the schema file and add it to git
- Update list of endpoints in this document

#### Permissions

There are two separate permission checks happening during an API request.
First, in the controller we have the usual `authorize!` guards. These check the general permission of the user to access the endpoint, and in the case of service tokens or oauth access tokens also whether the right scopes are set.
Second, in the graphiti resources `app/resources`, we return an `index_ability` which is used for fetching all accessible models from the database. For this there's specific abilities in `app/abilities/json_api`.
