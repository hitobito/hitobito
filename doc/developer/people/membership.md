# Membership

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
