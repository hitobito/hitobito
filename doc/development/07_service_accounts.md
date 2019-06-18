## Service Accounts

Service accounts allow to create a dedicated account with certain permissions for an external application. Using this account, the external application can then access the [JSON API](05_rest_api.md). Service accounts are created on a layer by an authorized person, and also persist once this person leaves the group or is deleted.

#### Permissions
Keys can be managed by using the "API-Keys" tab by people with `:layer_and_below_full` and `:layer_full` [permissions](../architecture/08_konzepte.md) on the layer. This usually includes only the main leader roles in each layer, address manager is not enough.

The permissions are not inherited downwards. The API-Keys of the underlying layers are therefore not visible.

#### Creating Service Tokens
During creation, the permissions of a service account / service token can be defined. If no level is selected, no information will be accessible using the token.

| Name (DE)                                        | Comment (EN)                                  |
| ---                                              | ---                                           |
| Personen dieser Ebene                            | People within the current layer are visible   |
| Personen dieser und der darunterliegenden Ebenen | People within the layer and below are visible |
| Events dieser und der darunterliegenden Ebenen   | Events within the layer and below are visible |
| Gruppen dieser und der darunterliegenden Ebenen  | Groups within the layer and below are visible |


#### Accessing the JSON-API

All endpoints except for the root group endpoint (`/groups`) from the [JSON API](05_rest_api.md) are accessible using service accounts. As with personal tokens, there are two possibilities to use the API:

* **Query parameter**: Send `token` as query parameter in the URL, and append `.json` to the URL path
```bash
curl "https://demo.hitobito.ch/de/groups/1.json?token=DtmPJ1iimjJi2neQQDq8efrqS5gBa7-5b8ZxboBCFdAm4HBBBP"
```

* **Request headers**: Set the following headers on the HTTP request: `X-Token` and `Accept` (set this to `application/json`)
```bash
curl -H "X-Token: DtmPJ1iimjJi2neQQDq8efrqS5gBa7-5b8ZxboBCFdAm4HBBBP" \
     -H "Accept: application/json" \
     https://demo.puzzle.ch/de/groups/1
```
