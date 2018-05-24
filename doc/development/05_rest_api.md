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
         http://demo.hitobito.ch/users/sign_in.json

To use the rest of the API there are two possibilities:

* **Parameters**: You provide `user_email` and `user_token` as paramateres in the path, the path has to end with `.json` (Example: `/groups/1.json?user_email=zumkehr@puzzle.ch&user_token=abcdef`).
* **Headers**: Set the header like this: `X-User-Email`, `X-User-Token` and `Accept` (=`application/json`) 

### Endpoints

Currently the following endpoints are provided:

| Method | Path                         | Function |
| --- | --- | --- |
| GET     | /groups                      | Root group           |
| GET     | /groups/:id                  | Group Details        |
| GET     | /groups/:id/people           | People of a certain group |
| GET     | /groups/:group_id/people/:id | Person details      |


### Example Response of a Sign In Request

    {
      people: [ {
        id: 446,
        href: http://demo.hitobito.ch/groups/1/people/446.json,
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
            href: http://demo.hitobito.ch/users/token.json,
            method: "POST"
          }
          token.delete: {
            href: http://demo.hitobito.ch/users/token.json,
            method: "DELETE"
          }
        }
      } ]
    }
