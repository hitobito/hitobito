# Rake Tasks
In the table below you find all rake tasks which we make use of in hitobito. Run the following rake tasks inside rails, rails-test container:

| Task                      | Beschreibung                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------ |
| `rake hitobito:abilities` | Alle Abilities ausgeben.                                                                               |
| `rake hitobito:roles`     | All Gruppen, Rollen und Permissions ausgeben.                                                          |
| `rake annotate`           | Spalten Informationen als Kommentar zu ActiveRecord Modellen hinzufügen.                               |
| `rake rubocop`            | Führt die Rubocop Must Checks (`rubocop-must.yml`) aus und schlägt fehl, falls welche gefunden werden. |
| `rake rubocop:report`     | Führt die Rubocop Standard Checks (`.rubocop.yml`) aus und generiert einen Report für Jenkins.         |
| `rake brakeman`           | Führt `brakeman` aus.                                                                                  |
| `rake mysql`              | Lädt die MySql Test Datenbank Konfiguration für die folgednen Tasks.                                   |
| `rake license:insert`     | Fügt die Lizenz in alle Dateien ein.                                                                   |
| `rake license:remove`     | Entfernt die Lizenz aus allen Dateien.                                                                 |
| `rake license:update`     | Aktualisiert die Lizenz in allen Dateien oder fügt sie neu ein.                                        |
| `rake ci`                 | Führt die Tasks für einen Commit Build aus.                                                            |
| `rake ci:nightly`         | Führt die Tasks für einen Nightly Build aus.                                                           |
| `rake ci:wagon`           | Führt die Tasks für die Wagon Commit Builds aus.                                                       |
| `rake ci:wagon:nightly`   | Führt die Tasks für die Wagon Nightly Builds aus.                                                      |
---
