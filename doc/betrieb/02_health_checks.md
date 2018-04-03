# Health Checks

## App

Der Endpoint */healthz* kann für einen generellen Health-Check der Applikation getriggert werden.
Gibt HTTP Status Code 200 zurück solange die Applikation einwandfrei läuft. Im Fehlerfall wird der
Status Code 503 zurück gegeben.
Dieser Endpoint kann z.B. für die Health-Checks von Openshift verwendet werden.

## Mail

Der Endpoinnt */healthz/mail?token=abcdefg123* prüft ob die Mails im Catch-All Konto regelmässig abgearbeitet werden. Ist dies nicht der Fall, wird der HTTP Status Code 503 zurück gegeben.
Der Zugriff ist nur mit einem gültigen Token möglich.
Um diesen Token für die entsprechende Umgebung zu erhalten kann auf der Konsole folgender Befehl verwendet werden:

```bundle exec rake app_status:auth_token```
