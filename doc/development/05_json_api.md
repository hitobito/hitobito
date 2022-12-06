## JSON Api 

This documentation is about the new JSON API introduced in 2022. Check the [legacy Api documentation](05_rest_api.md) for the old Api.

The hitobito JSON API implements the open standard **[json:api](https://jsonapi.org) v1.0** with media type **[application/vnd.api+json](http://www.iana.org/assignments/media-types/application/vnd.api+json)**

### Endpoints

Currently the following endpoints are provided:

| Method | Path                                              | Function                                                                        |
| ---    | ---                                               | ---                                                                             |
| GET    | /api/people/                                      | List all accessible people                                                      |
| GET    | /api/people/:id                                   | Fetch a single person entry, replace :id with the person's primary key          |

### Tools

Vandal is an integrated UI for developing / testing Json Api queries. Just open [/api/vandal](/api/vandal) with your browser to open the playground.

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

For development purposes or async requests, the API can also be accessed with the current user web session. Just login as user and then visit any `/api` endpoints or use Vandal.
