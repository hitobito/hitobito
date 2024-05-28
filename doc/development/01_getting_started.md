![hitobito logo](https://user-images.githubusercontent.com/9592347/184715060-351453d4-d066-4ff6-8f82-95d3b524b62f.svg)
## Getting started 🍀🍀🌅

To get started with the project following steps are required:

### Stage 1: Get Hitobito to run locally

- [ ] Setup Project locally, please follow the instructions at [Development](https://github.com/hitobito/development/) 
for the recommended 🚢 docker development setup.


- [ ] Make sure Tests 👨‍🔬 are running, look at [Tests](02_testing)


- [ ] Check if you can access the mailcatcher which run on [http://localhost:1080](http://localhost:1080)


- [ ] Look 👁️ at the table with all specific rake tasks in it, try some of them if interested [Rake Tasks](#specific-rake-tasks) 

Run the following rake tasks inside rails, rails-test container:

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

### Stage 2: Get to know the patterns and technologies

- [ ] Read and understand the [guidelines](03_guidelines.md) of Hitobito 


- [ ] Make yourself familiar with the DRY-CRUD Pattern [dry-crud-gem](https://github.com/codez/dry_crud)


- [ ] Learn about [wagons](04_wagons.md) 🚃


- [ ] Get to know our [Frontend & Assets](09_frontend/frontend)


- [ ] Understand our [CI/CD](06_ci_cd.md) Workflow 🛠️

---

### Stage 3: Start with coding


- [ ] Look at the Github Board: [Github Project](https://github.com/orgs/hitobito/projects/14)


- [ ] Grab a ticket which matches your skills


- [ ] Check in the section below to which module your ticket belongs to.


- [ ] Start contributing ‍💙🚀🚀
