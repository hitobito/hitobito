## Service Accounts

Service accounts allow impersonal access to the [REST API](../05_rest_api.md). API-Keys are created per layer (e.g. per canton or per local group) by an authorized person. They remain in place even if this person leaves the group or is deleted. Keys can be managed by using the tab "API-Keys" with with appropriate permissions. 

#### Permissions
Keys can be created by people with :layer_and_below_full and :layer_full permissions on their respective layers.
The permissions are not inherited downwards. The API-Keys of the underlying layers are therefore not visible.

#### Creating Service Tokens
During creation, different access levels can be defined per Service Token. If no level is selected, no information will be accessible using the token.

| Name (DE)  | Comment (EN) |
| --- | --- |
| Personen dieser Ebene | People within the current layer are visible |
| Personen dieser und der darunterliegenden Ebenen | People on layers below are visible |
| Events dieser und der darunterliegenden Ebenen | Events within the layer and below are visible |
| Gruppen dieser und der darunterliegenden Ebenen | Groups within the layer and below are visible |


#### Accessing the JSON-API
##### Params Style
~~~~ 
# Notation
[Base_URL][Endpoint]?token=[Token]

# Example
https://demo.hitobito.ch/de/groups/1.json?token=ABcdefGaHC
~~~~ 

##### Headers Style
~~~~ 
# Example
curl -i -H "X-Token: ABcdefGaHC" -H "Content-Type: application/json" https://demo.puzzle.ch/de/groups/1.json
~~~~