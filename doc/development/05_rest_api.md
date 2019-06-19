## REST API

Hitobito offers a read-only JSON REST API that gives access to the basic data stored in the database. The output format follows the conventions of [json:api](http://jsonapi.org) (although in an older version according to this issue https://github.com/hitobito/hitobito/issues/207). The API currently does not set any CORS headers, so it has to be consumed server-side (querying it in JavaScript in a browser is not possible).

### Authentication
* To use the API you need an authentication token.
* Every user account can create personal tokens.
* The tokens have the same permissions as the corresponding user.
* Tokens have no expiration date, but can be actively deleted by the user.
* There are also impersonal tokens ([service accounts](07_service_accounts.md)), that are meant to represent external applications.

> :bangbang: If you have an application that needs to read data from hitobito, you'll probably want to use [service accounts](07_service_accounts.md).

If you still want to use personal tokens, they can be managed using the following HTTP endpoints:

| Method  | Path                | Function             |
| ---     | ---                 | ---                  |
| POST    | /users/sign_in.json | read/generate token  |
| POST    | /users/token.json   | generate a new token |
| DELETE  | /users/token.json   | delete token         |

You have to pass `person[email]` and `person[password]` in the request body. Also, you have to set the `Content-Type: application/x-www-form-urlencoded` HTTP header.

With `curl` it looks like this (it sets the `Content-Type` header automatically):
```bash
curl -d "person[email]=mitglied@hitobito.ch" \
     -d "person[password]=demo" \
     https://demo.hitobito.ch/users/sign_in.json
```

The response will contain the personal token (`authentication_token`) in the JSON response (formatted here for readability):
```json
{
    "people": [
        {
            "id": "164",
            "type": "people",
            "href": "https://demo.hitobito.ch/de/groups/17/people/164.json",
            "first_name": "Boris",
            "last_name": "Becker",
            "nickname": "Eaque",
            "company_name": "",
            "company": false,
            "gender": "w",
            "email": "mitglied@hitobito.ch",
            "authentication_token": "yhFrXcydFwisXYLEUFyV",
            "last_sign_in_at": "2019-06-19T13:24:11.000+02:00",
            "current_sign_in_at": "2019-01-01T12:00:00.000+02:00",
            "links": {
                "primary_group": "17"
            }
        }
    ],
    "linked": {
        "groups": [
            {
                "id": "17",
                "name": "Abos Stadt Bern",
                "group_type": "Lokalgruppe/Sektion"
            }
        ]
    },
    "links": {
        "token.regenerate": {
            "method": "POST",
            "href": "https://demo.hitobito.ch/de/users/token.json",
            "type": "tokens"
        },
        "token.delete": {
            "method": "DELETE",
            "href": "https://demo.hitobito.ch/de/users/token.json",
            "type": "tokens"
        }
    }
}
```

To use the API with the personal token, there are two possibilities:

* **Query parameter**: Send `user_email` and `user_token` as query parameters in the URL, and append `.json` to the URL path
```bash
curl "https://demo.hitobito.ch/groups/1.json?user_email=mitglied@hitobito.ch&user_token=yhFrXcydFwisXYLEUFyV"
```

* **Request headers**: Set the following headers on the HTTP request: `X-User-Email`, `X-User-Token` and `Accept` (set this to `application/json`)
```bash
curl -H "X-User-Email: mitglied@hitobito.ch" \
     -H "X-User-Token: yhFrXcydFwisXYLEUFyV" \
     -H "Accept: application/json" \
     https://demo.hitobito.ch/groups/1
```


### Endpoints

Currently the following endpoints are provided:

| Method | Path                            | Function                                                                        |
| ---    | ---                             | ---                                                                             |
| GET    | /groups                         | Redirects to root group (only works using personal token, not service accounts) |
| GET    | /groups/:id                     | Group details                                                                   |
| GET    | /groups/:id/people              | People of a certain group                                                       |
| GET    | /groups/:group_id/people/:id    | Person details                                                                  |
| GET    | /groups/:group_id/events        | Events of a certain group                                                       |
| GET    | /groups/:group_id/events/:id    | Event details                                                                   |
| GET    | /groups/:group_id/events/course | Courses of a certain group                                                      |



### Events endpoint

The events and the course endpoints have some query parameters, as explained below.

| Name       | Type     | Description                                                          | Default               | Available Values                           | Example                 |
| ---        | ---      | ---                                                                  | ---                   | ---                                        | ---                     |
| type       | `string` | Specify class type                                                   | Nil (normal event)    | `Event::Course` and wagon specific classes | `type=Event::Course`    |
| filter     | `string` | Specify whether to only display events from the current layer        | `all`                 | `all`, `layer`                             | `filter=layer`          |
| start_date | `date`   | Filter events ending after or at start_date (not working right now)  | Today                 | Any date                                   | `start_date=31-10-2018` |
| end_date   | `date`   | Filter events starting before or at end_date (not working right now) | Nil (upcoming events) | Any date                                   | `end_date=28-02-2019`   |

An example query with its response (formatted here for readability) can be seen below.

```bash
curl "https://demo.hitobito.ch/groups/1/events.json?user_email=mitglied@hitobito.ch&user_token=yhFrXcydFwisXYLEUFyV&filter=layer"
```

```json
{
  "events": [
    {
      "id": "1",
      "type": "events",
      "name": "LK 102",
      "description": "Aut exercitationem quia. Sed vel optio. Veritatis deserunt in consequuntur excepturi. Tenetur in dolores veniam vero quas dolor.",
      "motto": "Laboriosam amet id hic quo saepe et corrupti repellendus.",
      "cost": "",
      "maximum_participants": 38,
      "participant_count": 0,
      "location": "Ankerweg 7\r\n84377\r\nHannahscheid",
      "application_opening_at": "2017-10-28",
      "application_closing_at": "2019-02-03",
      "application_conditions": "",
      "state": "",
      "teamer_count": 6,
      "external_application_link": "http://demo.hitobito.ch/de/groups/1/public_events/1",
      "links": {
        "kind": "1",
        "dates": [
          "1"
        ],
        "groups": [
          "1"
        ]
      }
    }
  ],
  "linked": {
    "event_kinds": [
      {
        "id": "1",
        "label": "Leitungskurs",
        "short_name": "LK",
        "minimum_age": null,
        "general_information": null,
        "application_conditions": null
      }
    ],
    "event_dates": [
      {
        "id": "1",
        "label": "Kurs",
        "start_at": "2018-02-02T00:00:00.000+01:00",
        "finish_at": "2018-02-10T00:00:00.000+01:00",
        "location": ""
      }
    ],
    "groups": [
      {
        "id": "1",
        "href": "http://demo.hitobito.ch/de/groups/1.json",
        "group_type": "Hauptebene",
        "layer": true,
        "name": "Dachverband",
        "short_name": "Dachverband",
        "email": "alta.haley@example.org",
        "address": "Schellingstr. 8",
        "zip_code": 5692,
        "town": "Damianburg",
        "country": null,
        "created_at": "2018-11-08T14:39:36.000+01:00",
        "updated_at": "2018-11-08T14:39:36.000+01:00",
        "deleted_at": null,
        "links": {
          "layer_group": "1",
          "hierarchies": [
            "1"
          ],
          "children": [
            "3",
            "4",
            "5",
            "6",
            "16",
            "11",
            "2"
          ]
        }
      },
      {
        "id": "1",
        "name": "Dachverband",
        "group_type": "Hauptebene"
      },
      {
        "id": "3",
        "name": "Geschäftsstelle",
        "group_type": "Geschäftsstelle"
      },
      {
        "id": "4",
        "name": "Kontakte",
        "group_type": "Kontakte"
      },
      {
        "id": "5",
        "name": "Mitglieder",
        "group_type": "Mitglieder"
      },
      {
        "id": "6",
        "name": "Region Bern",
        "group_type": "Region/Kanton"
      },
      {
        "id": "16",
        "name": "Region Nordost",
        "group_type": "Region/Kanton"
      },
      {
        "id": "11",
        "name": "Region Zürich",
        "group_type": "Region/Kanton"
      },
      {
        "id": "2",
        "name": "Vorstand",
        "group_type": "Vorstand"
      }
    ]
  },
  "links": {
    "groups.creator": {
      "href": "http://demo.hitobito.ch/de/people/{groups.creator}.json",
      "type": "people"
    },
    "groups.updater": {
      "href": "http://demo.hitobito.ch/de/people/{groups.updater}.json",
      "type": "people"
    },
    "groups.deleter": {
      "href": "http://demo.hitobito.ch/de/people/{groups.deleter}.json",
      "type": "people"
    },
    "groups.parent": {
      "href": "http://demo.hitobito.ch/de/groups/{groups.parent}.json",
      "type": "groups"
    },
    "groups.layer_group": {
      "href": "http://demo.hitobito.ch/de/groups/{groups.layer_group}.json",
      "type": "groups"
    },
    "groups.hierarchy": {
      "href": "http://demo.hitobito.ch/de/groups/{groups.hierarchy}.json",
      "type": "groups"
    },
    "groups.children": {
      "href": "http://demo.hitobito.ch/de/groups/{groups.children}.json",
      "type": "groups"
    },
    "groups.people": {
      "href": "http://demo.hitobito.ch/de/groups/{groups.id}/people.json",
      "type": "people"
    }
  }
}
```
