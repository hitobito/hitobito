# People

## Overview
* [Authentication](#authentication)
* [OAuth](#oauth)
* [Membership](#membership)
* [Address completion](address_completion.md)
* [Locations](locations.md)

## Authentication

The widely used gem [Devise](https://github.com/heartcombo/devise) serves as the basis for user authentication in Hitobito

### Login Attribute Person

Additional attributes can be defined in a wagon which can be used as the ID of the person
for login. For example, instead of just the main e-mail (default), a member
a member number can also be used for the login.

```ruby
module SacCas::Person
  extend ActiveSupport::Concern

  included do
    ...
    self.devise_login_id_attrs << :membership_number
    ...
  end
end
```

## OAuth

Hitobito is an OAuth 2.0 provider, meaning that an external application can authenticate users via hitobito (usually in the form of a ‘Login via hitobito’ feature, similar to Google and Facebook etc.). The external application can then query information about the user, if the user has granted this permission. OAuth authentication also allows the external application to use the JSON API. The external application has the same permissions as the user.
More info: [OAuth](oauth.md)

## Membership

The concept of membership was introduced with the SKV and later the SAC/CAS. This concept revolves around the possible active or inactive memberships that a person can have in a club.

Technical namespace: `People::Membership`.

### Verification

`People::Membership::VerifyController` provides an endpoint that can be used to check for active membership. The following states are available:
- Membership valid
- Membership invalid
- Invalid verification code

Url: `https://hitobito.example.com/membership_verify/afEdffe32334gadtoken`

To activate the verify endpoint, the method `member?` in the class `People::Membership::Verifier` must be implemented in the wagon:

```ruby
...
module Skv::People::Membership::Verifier
  extend ActiveSupport::Concern

  def member?
    @person.roles.any? do |r|
      r.kind != :external
    end
  end

end
```

wagon.rb
```ruby
People::Membership::Verifier.prepend Skv::People::Membership::Verifier
```
#### QR Code

The class `People::Membership::VerificationQrCode` provides a generator to generate a scannable QR code for accessing a person's verify endpoint.
