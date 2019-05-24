## Setup mit Docker

Für allgemeine Informationen zum Setup siehe [Setup](01_setup.md)

### System

Auf der Umgebung muss `docker` (oder containerd) und `docker-compose` installiert sein.

Die Umgebung ist mit folgenden Services vorkonfiguriert:

* **web**: hitobito Web ([http://localhost:3000](http://localhost:3000))
* **worker**: Hintergrundverarbeitung
* **mail**: Versendete Emails ([http://localhost:1080](http://localhost:1080))

### Setup

Die Konfiguration kann grundsätzlich über `docker-compose.yml` und die ENVIRONMEN-Variablen darin vorgenommen werden.

Applikation starten:

    docker-compose up

Kommando ausführen (z. B. bin/rails c)

    docker-compose run app bin/rails c


### Wagons

Die Wagons müssen gemäss [Setup](01_setup.md) separat installiert werden. Danach können sie mittels `docker-compose.yml` als Volumes im Root der Container gemounted werden:

```
...
volumes:
    ...

    # mount wagons
    - ../hitobito_youth:/hitobito_youth:ro
    - ../hitobito_pbs:/hitobito_pbs:ro
```

### Tests

Ausführen der Tests:

    docker-compose -f docker-compose.test.yml run tests
