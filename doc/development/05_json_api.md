## JSON Api 

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
