# People

## Authentication

Als Basis für die Benutzer-Authentifizierung in Hitobito dient das weit verbreitete Gem [Devise](https://github.com/heartcombo/devise)

### Login Attribute Person

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

## Membership

Mit dem SKV und später dem SAC/CAS wurde das Konzept der Mitgliedschaft (Membership) eingeführt. Dieses Konzept dreht sich rund um die möglichen aktiven oder auch inaktiven Mitgliedschaften die eine Person in einem Verein haben kann.

Technischer Namespace: `People::Membership`

### Verification

`People::Membership::VerifyController` bietet einen Endpoint über den auf eine aktive Mitgliedschaft geprüft werden kann. Es gibt dabei folgende Zustände:
- Mitgliedschaft gültig
- Mitgliedschaft ungültig
- Ungültiger Verifikationscode

Url: `https://hitobito.example.com/membership_verify/afEdffe32334gadtoken`

Um den Verify-Endpoint zu aktivieren muss im Wagon die Methode `member?` in der Klasse `People::Membership::Verifier` implementiert werden:

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

Die Klasse `People::Membership::VerificationQrCode` bietet einen Generator um einen scanbaren QR Code zu generieren für den Zugriff auf den Verify-Endpoint einer Person.
