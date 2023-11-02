# Authentication

Als Basis für die Benutzer-Authentifizierung in Hitobito dient das weit verbreitete Gem [Devise](https://github.com/heartcombo/devise)

## Login Attribute Person

In einem Wagon können weitere Attribute definiert werden welche als ID der Person
zur Anmeldung verwendet werden können. z.B. anstatt nur der Haupt-E-Mail (Standard) kann
auch eine Mitglieder-Nr. für das Login verwendet werden.

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
