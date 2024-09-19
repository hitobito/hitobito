# Definition of Done

Folgende Punkte sind zu beachten, damit ein Issue als fertig implementiert gilt:

- Das Feature wurde in entsprechender Rolle durchgeklickt und manuell getest. Nicht Admin verwenden!
- Tests sind geschrieben und laufen ohne Fehler durch.
- Die Implementation ist auch bei produktiven Datenmengen performant (z.B. > 100'000 Personen) und weist keine n+1 Queries auf.
- Commits sind in sich abgeschlossen (= einzeln lauffähig) und auf eine minimale Anzahl gesquashed.
- Commit Messages sind Englisch, beginnen mit einem Grossbuchstaben, verwenden die Befehlsform und enthalten am Ende immer eine Referenz zum Ticket (z.B. `(#42)`). Falls sich dieses in einem anderen Repo befindet, kann die Referenz auf einer neuen Zeile angegeben werden (z.B. `(hitobito/hitobito_pbs#42)`).
- [User-Dokumentation](https://hitobito.readthedocs.io/de/latest/) ist geschrieben.
- [Entwickler-Dokumentation](https://github.com/hitobito/hitobito/tree/master/doc) ist geschrieben.
- [Changelog](../../../CHANGELOG.md) Eintrag ist erstellt.
