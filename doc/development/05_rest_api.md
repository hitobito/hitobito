## REST API

The JSON format follows the conventions of [json:api](http://jsonapi.org) (although in an older version according to this issue https://github.com/hitobito/hitobito/issues/207)

### Authentication

* To use the APi you need an authentication-token.
* Every useraccount can create such a token.
* There are no tokens independent of a user account. 
* The token has the same permissions as the corresponding user.
* Tokens have no expiration date.

There are the following HTTP endpoints: 


| Method  | Path                | Function |
| --- | --- | --- |
| POST    | /users/sign_in.json | read/generate token |
| POST    | /users/token.json   | generate a new token |
| DELETE  | /users/token.json   | delete token |

You have to pass `person[email]` and `person[password]` as parameters.

With `curl` it looks like this:

    curl -d "person[email]=mitglied@hitobito.ch" \
         -d "person[password]=demo" \
         https://demo.hitobito.ch/users/sign_in.json

To use the rest of the API there are two possibilities:

* **Parameters**: You provide `user_email` and `user_token` as paramateres in the path, the path has to end with `.json` (Example: `/groups/1.json?user_email=zumkehr@puzzle.ch&user_token=abcdef`).
* **Headers**: Set the header like this: `X-User-Email`, `X-User-Token` and `Accept` (=`application/json`) 

### Endpoints

Currently the following endpoints are provided:

| Method | Path                            | Function                   |
| ---    | ---                             | ---                        |
| GET    | /groups                         | Root group                 |
| GET    | /groups/:id                     | Group Details              |
| GET    | /groups/:id/people              | People of a certain group  |
| GET    | /groups/:group_id/people/:id    | Person details             |
| GET    | /groups/:group_id/events        | Events of a certain group  |
| GET    | /groups/:group_id/events/course | Courses of a certain group |
| GET    | /groups/:group_id/events/:id    | Event details              |


### Parameters

    /groups/:group_id/events

| Name       | Type     | Description                    | Default               | Available Values                           | Example                 |
| ---        | ---      | ---                            | ---                   | ---                                        | ---                     |
| type       | `string` | Specifiy class type            | Nil (Normal Event)    | `Event::Course` and wagon specific classes | `type=Event::Course`    |
| filter     | `string` | Specifiy filter type           | `all`                 | `all`, `layer`                             | `filter=layer`          |
| start_date | `date`   | Filter Events after start_date | Today                 | Any date                                   | `start_date=31-10-2018` |
| end_date   | `date`   | Filter Events before end_date  | Nil (Upcoming Events) | Any date                                   | `end_date=28-02-2019`   |

### Example Response

#### Sign In Request

    {
      people: [ {
        id: 446,
        href: https://demo.hitobito.ch/groups/1/people/446.json,
        first_name: "Pascal",
        last_name: "Zumkehr",
        nickname: null,
        company_name: null,
        company: false,
        gender: null,
        email: "zumkehr@puzzle.ch",
        authentication_token: "9DDNdpV4hwM76f3J6oNV",
        last_sign_in_at: "2014-07-08T15:40:01.154+02:00",
        current_sign_in_at: "2014-07-08T16:28:02.577+02:00",
        links: {
          primary_group: "1"
        }
      } ]
      linked: {
        groups: [ {
          id: "1",
          name: "CEVI Schweiz",
          group_type: "Dachverband"
        } ]
      }
      links: {
          token.regenerate: {
            href: https://demo.hitobito.ch/users/token.json,
            method: "POST"
          }
          token.delete: {
            href: https://demo.hitobito.ch/users/token.json,
            method: "DELETE"
          }
        }
      } ]
    }

#### GET /groups/:group_id/events

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
