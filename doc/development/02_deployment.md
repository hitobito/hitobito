## Deployment und Betrieb

Hitobito kann wie die meisten Ruby on Rails Applikationen auf verschiedene Arten 
[deployt](http://rubyonrails.org/deploy/) werden. 
Folgende Umsysteme müssen vorgängig eingerichtet werden:

* Ruby >= 2.5
* Apache HTTPD
* Phusion Passenger
* MySql
* Memcached
* Sphinx (optional)
* Eine Catch-All E-Mail Adresse einer bestimmte Domain für die Mailinglisten (optional)
* SSL Zertifikat (optional)
* Sentry (optional)

### Konfiguration

Um hitobito mit den Umsystemen zu verbinden und zu konfigurieren, können folgende Umgebungsvariablen 
gesetzt werden. Werte ohne Default müssen in der Regel definiert werden. 

| Umgebungsvariable | Beschreibung | Default |
| --- | --- | --- |
| RAILS_HOST_NAME | Öffentlicher Hostname der Applikation. Wird für Links in E-Mails verwendet. | - |
| RAILS_HOST_SSL | Gibt an, ob die Applikation unter HTTPS läuft (`true` or `false`) | `false` |
| RAILS_DB_NAME | Name der Datenbank | `hitobito_[environment]` |
| RAILS_DB_USERNAME | Benutzername, um auf die Datenbank zu verbinden. | - |
| RAILS_DB_PASSWORD | Passwort, um auf die Datenbank zu verbinden. | - |
| RAILS_DB_HOST | Hostname der Datenbank | - |
| RAILS_DB_PORT | Port der Datenbank | - |
| RAILS_DB_ADAPTER | Datenbank adapter | `mysql2` |
| RAILS_MAIL_DELIVERY_METHOD | `smtp` oder `sendmail`. Siehe [ActionMailer](http://api.rubyonrails.org/classes/ActionMailer/Base.html) für Details. | `sendmail` |
| RAILS_MAIL_DELIVERY_CONFIG | Eine Komma-separierte `key: value` Liste mit allen erforderlichen E-Mail Sendeeinstellungen der gewählten Methode, z.B. `address: smtp.local, port: 25`. Siehe [ActionMailer](http://api.rubyonrails.org/classes/ActionMailer/Base.html) für gültige Optionen. Wenn diese Variable leer ist, werden die Rails Defaultwerte verwendet. | Rails defaults |
| RAILS_MAIL_DOMAIN | Der Domainname für die Mailinglisten/Abos | `RAILS_HOST_NAME` |
| RAILS_MAIL_RETRIEVER_TYPE | `pop3` oder `imap`, alles was vom [Mail](https://github.com/mikel/mail) Gem unterstützt wird. | `pop3` |
| RAILS_MAIL_RETRIEVER_CONFIG | Eine Komma-separierte `key: value` Liste mit allen erforderlichen E-Mail Empfangseinstellungen des gewählten Typs, z.B. `address: mailhost.local, port: 995, enable_ssl: true`. Siehe [Mail](https://github.com/mikel/mail#getting-emails-from-a-pop-server) für gültige Optionen. Wenn diese Variable nicht gesetzt ist, funktionieren die Mailinglisten nicht. | - |
| RAILS_SPHINX_HOST | Hostname des Sphinx Servers | 127.0.0.1 |
| RAILS_SPHINX_PORT | Eindeutiger Port des Sphinx Servers. Muss für jede laufende Instanz eindeutig sein. | 9312 |
| MEMCACHE_SERVERS | Komme-getrennte Liste von Memcache Servern in der Form `host:port` | localhost:11211 |
| SENTRY_DNS | Configuration der Sentry Instanz, an welche Fehler gesendet werden sollen. Falls diese Variable nicht gesetzt ist, werden keine Fehlermeldungen verschickt. | - |



### Inbetriebnahme

Einmal installiert, müssen zur Inbetriebnahme von hitobito noch folgende Schritte unternommen 
werden:

#### Setup (Entwickler)

1. Integration: Laden der [Seed Daten](#dummy-daten-development-seed).
1. Produktion: Setzen des Passworts des [Root Users](#root-user) über die Passwort vergessen 
Funktion.
1. Erstellen eines Benutzers für den Kunden mit einer Haupt/Admin Rolle.
1. Einrichten einer [Noreply Liste](#no-reply-liste) in einer geeigneten Gruppe.

#### Smoke Tests (Entwickler)

* Full Text Search liefert Resultate (Suchfeld oben rechts)
* Mails werden über Mailing Listen empfangen und weitergeschickt (z.B. via noreply Liste)
* Die Links in den gesendeten Emails sind https (z.B. Passwort vergessen)
* Errbit erhält Fehlermeldungen (Konsole: `rake airbrake:test`)

#### Einrichten (Kunde)

1. Anpassen und Übersetzen der Texte (Admin > Texte).
1. Erfassen von Etikettenformaten, Qualifikationen und Kurstypen.
1. Erfassen von weiteren Gruppen.
1. Erfassen von Personen und diesen ein Login Email schicken.


#### Root User

Die Emailadresse des Root User ist in `RAILS_ROOT_USER_EMAIL` oder im `settings.yml` des
entsprechenden Wagons definiert und wird automatisch über die Seed Daten in die Datenbank geladen. 
Über die Passwort vergessen Funktion kann dafür ein Passwort gesetzt werden. Danach können weitere 
Personen für den Kunden erstellt werden. Der Root User bleibt die einzige Person, mit welcher sich 
Entwickler auf der Produktion einloggen können. Auf der Produktion wird dem Root User keine Gruppe geseedet.
Um dem Root eine Gruppe/Rolle zu geben, gibt es die `assign_role_to_root` Methode auf der `PersonSeeder` Klasse.

#### No-Reply Liste

Damit jemand bei ungültigen E-Mailadressen oder sonstigen Versandfehlern von E-Mails benachrichtigt 
wird, sollte eine spezielle Mailingliste (in der Applikation unter "Abos" > "Abo erstellen") 
eingerichtet werden, welche auf die Applikations-Sendeadresse lautet (`Settings.email.sender`, z.B. 
`noreply@db.jubla.ch`). Als zusätzlicher Absender muss dabei der verwendete Mailer Daemon definiert 
werden (z.B. `MAILER-DAEMON@puzzle.ch`). Bei dieser Liste sollte eine Person der Organisation als 
Abonnent vorhanden sein, welcher sich um die fehlerhaften Adressen kümmert.

#### Dummy Daten (Development Seed)

Um auf der Integration die Development Seed Daten zu laden, kann folgender Symlink erstellt werden. 
Dies lädt die im Core und dem Wagon definierten Development Seed Daten.

    cd db/seeds && ln -s development/ production
    cd vendor/wagons/hitobito_[wagon]/db/seeds && ln -s development/ production

Alle geseedeten Personen haben Dummy Email Adressen und das selbe Passwort (in den Seed Daten 
definiert). Dadurch kann man sich ohne weiteres als eine andere Person einloggen und die Applikation 
in dieser Rolle testen.

Achtung: Der Symlink sollte nach dem initalen Seeden wieder entfernt werden. Geschieht dies nicht, 
werden für neu (vom Benutzer) angelegten Gruppen bei folgenden Deployements entsprechend Mitglieder 
und Events geseeded.

#### Schweizer Addressdaten

Um die schweizer Addressdaten zu importieren kann der `bundle exec rake address:import` Task genutzt werden. Um die Addressdaten von der Post API zu fetchen, muss ein API Token gegeben sein (`ENV['ADDRESSES_TOKEN']`). 

#### 2FA mit TOTP

Die Zwei Faktor Authentifizierung wurde mit der [freeOTP](https://freeotp.github.io/) getestet und entwickelt.

Zur Inbetriebnahme werden keine Konfigurationen zwingend benötigt. Die 2FA kann ohne Konfiguration aktiviert und verwendet werden.

Mittles der Rolle kann die 2FA erzwungen werden. Erzwingen der 2FA erfolgt über das `settings.yml` indem der `role.type` unter `totp.forced_roles` eingetragen wird.

Beispiel:

```
totp:
  forced_roles:
    - Group::TopLayer::Administrator
    - Group::RegionBoard::President
```

### Umsysteme

Hitobito benötigt für den Betrieb einige weitere Dienste die installiert und konfiguriert werden müssen. 

#### Sphinx / Searchd

Damit es möglich ist über das Webfrontend nach Personen, Events und weiteren definierten Einträgen zu Suchen wird Sphinx verwendet. Über die Umgebungsvariablen RAILS_SPHINX_HOST und RAILS_SPHINX_PORT wird dabei definiert wie der Sphinx-Daemon erreichbar ist. 
Sphinx lässt sich unter Centos/Rhel folgendermassen installieren:
```
yum install sphinx
```
Um eine entsprechende Konfiguration für Sphinx zu generieren steht ein Rake Task zur Verfügung. Vor dem Ausführen dieses Befehls innerhalb des Rails Verzeichnisses muss sichergestellt sein das die zuvor erwähnten Environment Variablen für Host und Port gesetzt sind.
```
cd $rails_dir
bundle exec rake ts:configure
```
Über diesen Task wird nun eine entsprechende Sphinx Konfiguration unter config/production.sphinx.conf abgelegt. Diese erstellte Konfiguration linkt man nun am besten gleich nach /etc/sphinx/app-name.conf
```
ln -s $app_dir/config/production.sphinx.conf /etc/sphinx/$app-name.conf
```
Danach lässt sich der Sphinx Daemon mit der neuen Konfiguration starten:
```
service searchd start
```
