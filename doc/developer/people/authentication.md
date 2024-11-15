# Authentication

The widely used gem [Devise](https://github.com/heartcombo/devise) serves as the basis for user authentication in Hitobito

## Login Attribute Person

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

## Disabling of second factor (2fa) check for development

For local development the 2fa check can be disabled by setting `auth.skip_2fa = true` in `config/settings.local.yml`.
