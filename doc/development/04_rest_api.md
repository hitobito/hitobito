## REST API

Das JSON Format folgt den Konventionen von [json:api](http://jsonapi.org).

### Authentisierung

Für die Verwendung der API ist ein Authentisierungstoken nötig. Jeder Benutzeraccount
kann ein solches Token erstellen. Dieses Token ist danach mit dem Benutzeraccount
verknüpft und hat die selben Zugriffsrechte wie der/die Benutzer/in.

Ein Token ist für unbeschränkte Zeit gültig, es kann also z.B. in eine Webseite
eingebunden werden, ohne dass das Passwort verwendet werden muss.

Für die Verwaltung des Tokens dienen die folgenden HTTP Endpunkte:

| Methode | Pfad                | Funktion |
| --- | --- | --- |
| POST    | /users/sign_in.json | Token auslesen |
| POST    | /users/token.json   | Token neu generieren |
| DELETE  | /users/token.json   | Token löschen |

Als Parameter müssen immer `person[email]` und `person[password]` übergeben werden.

Mit `curl` geht das so:

    curl -d "person[email]=mitglied@hitobito.ch" \
         -d "person[password]=demo" \
         http://demo.hitobito.ch/users/sign_in.json

Um das Token bei der restlichen API zu verwenden, bestehen zwei Möglichkeiten:

* **Parameter**: `user_email` und `user_token` werden als Pfadparameter angegeben, der Pfad muss 
mit `.json` enden (Bsp: `/groups/1.json?user_email=zumkehr@puzzle.ch&user_token=abcdef`).
* **Headers**: `X-User-Email`, `X-User-Token` und `Accept` (=`application/json`) Header 
entsprechend setzen.

### Endpunkte

Folgende Endpunkte sind momentan definiert:

| Methode | Pfad                         | Funktion |
| --- | --- | --- |
| GET     | /groups                      | Hauptgruppe           |
| GET     | /groups/:id                  | Gruppen Details       |
| GET     | /groups/:id/people           | Personen einer Gruppe |
| GET     | /groups/:group_id/people/:id | Personen Details      |


### Beispielantwort auf den Sign In Request

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
