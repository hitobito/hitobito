# Architekur Dokumentation

Diese Dokumente beschreiben die wesentlichen architekturellen Aspekte von hitobito. Die Gliederung folgt [arc42](https://www.arc42.de/template). Mit `rake doc:arch` kann die eine HTML Datei mit der gesamten Dokumentation generiert werden.

## Inhalt

* [Einführung](01_einfuehrung.md)
* [Kontextabgrenzung](03_kontextabgrenzung.md)
* [Lösungsstrategie](04_loesungsstrategie.md)
* [Bausteinsicht](05_bausteinsicht.md)
* [Verteilungssicht](07_verteilungssicht.md)
* [Konzepte](08_konzepte.md)
* [Entwurfsentscheidungen](09_entwurfsentscheidungen.md)
* [Glossar](12_glossar.md)

Alle Diagramme werden mit [Draw.io](http://draw.io) erstellt und jeweils als Original .xml sowie als .svg abgespeichert.

## Techstack
Der aktuelle Techstack von hitobito sieht wie folgt aus:

* Applikation mit [RubyOnRails](http://rubyonrails.org)
* Datenbank Persistenz mit [MySQL](https://www.mysql.com/)
* Caching mit [Memcache](http://memcached.org)
* Search Enging [Sphinx](http://sphinxsearch.com/)
* Monitoring mit [Prometheus](https://prometheus.io/) und [Grafana](https://grafana.com/)
* Ausführen von [Background Jobs](https://github.com/collectiveidea/delayed_job)
* Plugin Framework: [Wagons](http://github.com/codez/wagons)
* Source Code [Git Hub](https://github.com/hitobito/)
* Container Plattform [APPUiO](https://www.appuio.ch)
* Open Source Lizenz: [GNU Affero General Public License](http://www.gnu.org/licenses/)
