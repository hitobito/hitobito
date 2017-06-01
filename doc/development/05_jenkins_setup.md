## Jenkins Setup

Um mit den verschiedenen Hitobito Projekten nicht zuviel Overhead zu erzeugen, werden die Jenkins Jobs wie folgt aufgeteilt. Damit werden die jeweiligen Tests nur einmal ausgeführt.

| Job | Generisch/Spezifisch | Beschreibung
|---|---|---|
| hitobito-core |	G |	Commit Build für den Core
| hitobito-core-nightly_master/stable |	G |	Nightly Build core
| hitobito-[wagon] |	S pro Instanz |	Commit Build für einen Wagon
| hitobito-[wagon]-nightly_master |	S pro Instanz | Nightly Build wagon
| hitobito-[wagon]-rpm | S pro Instanz | Wagon RPM Build Job

Alle Wagon Jobs müssen mit Multiple SCMs definiert werden, wobei Core und Wagon in jeweils verschiedene Verzeichnisse geklont werden (Erweitert > Local subdirectory for repo: hitobito bzw hitobito_[wagon]).

Jobs für Organisationen, welche bereits produktiv sind, basieren auf den jeweiligen Stable Branches. Jobs für Neu-/Weiterentwicklungen basieren auf den Master Branches.

Als Home Verzeichnis für alle Tasks und Reports muss danach hitobito gesetzt werden.

Damit die Änderungen am Core Repo bei Wagon Jobs keinen Commit Build triggert, müssen dort für das Core Repo alle Dateien ausgeschlossen werden (Erweitert > Included Regions: 'none'). Änderungen am Core, welche bei Wagons Probleme verursachen könnten, werden somit spätestens in den Nightly Builds erkannt (Core Repo Daten nicht ausgeschlossen). Dies ist ein Trade-off zwischen ständig laufenden Jobs, auf welche gewartet werden muss, und unmittelbarem Feedback.

### Umgebungsvariablen

Für alle Jobs muss eine ensprechende Test DB erstellt und konfiguriert werden. Jeder Job muss eine eigene DB erstellen, damit sich diese nicht in die Quere kommen. Dabei ist der Prefix 'jenkins_hitobito_' zu wählen. Die Jobs müssen ebenfalls einen eindeutigen RAILS_SPHINX_PORT sowie einen CAPYBARA_SERVER_PORT definieren.

Set environment variable names:

    HEADLESS=true
    CAPYBARA_SERVER_PORT=81??
    RAILS_SPHINX_PORT= 931?

    RAILS_DB_NAME=jenkins_hitobito_[wagon_job_branch]
    RAILS_DB_HOST=..
    RAILS_DB_PORT=3306
    RAILS_DB_ADAPTER=mysql2
    RAILS_DB_USERNAME=..
    RAILS_DB_PASSWORD=..


### hitobito-core: Commit Build für den Core

Läuft nach jedem Commit auf dem Core Repo (pitc_hit/hitobito.git), Master und Stable Branch.
   * Läuft die Rubocop Hard Conventions
   * Läuft die Core Specs

Rake Task:

    ci

##hitobito-core-nightly_master/stable: Nightly Build für den Core

Läuft jede Nacht bei Changes auf dem Core Repo Master und Stable Branch. Die gesamte Build History wird archiviert.

  * Läuft die Core Specs
  * Läuft Brakeman Analyse
  * Erstellt Model Diagram
  * Läuft Rubocop Report
  * Läuft Rails Stats

Rake Task: bundle exec rake ci:nightly tx:auth tx:push -t

### hitobito-[wagon]: Commit Build für einen Wagon

Läuft nach jedem Commit auf dem Wagon Repo, je nach dem auf dem Master oder Stable Branch.

  * Läuft die Rubocop Hard Conventions
  * Läuft die Wagon Specs

Rake Task:

    ci:wagon

Script: bin/ci/wagon_commit.sh

##hitobito-[wagon]-nightly_master: Nightly Build für einen Wagon, Master Branch

Läuft jede Nacht bei Changes auf dem Wagon Repo, Master Branch, falls der hitobito-core-nightly Job erfolgreich war. Die gesamte Build History wird archiviert.

  * Läuft die Wagon Specs
  * Läuft Brakeman Analyse
  * Erstellt Model Diagram
  * Läuft Rubocop Report
  * Läuft Tarantula Tests (Auto-crawling der App auf Test Fixtures)
  * Pusht ggf. Locale Dateien auf Transifex

Rake Task:

    bundle exec rake ci:wagon:nightly --trace && bundle exec rake wagon:exec CMD='rake app:tarantula:test app:tx:auth app:tx:push'

Script:

    bin/ci/wagon_nightly_master.sh


### Abhängigkeiten

Zum überprüfen, ob der hitobito-core-nightly Job erfolgreich war, wurde folgendes Script als erster Build Step verwendet. Dieses funktioniert leider nicht mehr, da die Jobs auf unterschiedlichen Build Nodes ablaufen können und daher keinen Zugriff aufeinander haben. D.h., dass momentan ein Wagon Nightly Job erfolgreich sein kann, obwohl der Core Nightly failed. Damit können fehlerhafte Cores deployt werden.

    # check that hitobito-core-nightly is successfull before continueing

    path = File.join(ENV['JENKINS_HOME'], 'jobs', 'hitobito-core-nightly', 'builds', '*-*-*')
    last_build = Dir.glob(path).sort.last
    xml = File.read(File.join(last_build, 'build.xml'))
    result = xml[/<result>(.+?)<\/result>/, 1]

    if result.strip.downcase != 'success'
      puts "hitobito-core-nightly is currently #{result}, aborting."
      exit 1
    end

Dadurch failt der Job direkt, falls hitobito-core-nightly nicht successfull ist.

### hitobito-[wagon]-nightly_stable: Nightly Build für einen Wagon, Stable Branch

Läuft jede Nacht bei Changes auf dem Wagon Repo, Stable Branch, falls der hitobito-core-nightly Job erfolgreich war.

  * Läuft die Wagon Specs
  * Läuft Tarantula Tests (Auto-crawling der App auf Test Fixtures)

Rake Task:

    bundle exec rake ci:wagon --trace && bundle exec rake wagon:exec CMD='rake app:tarantula:test'

Script:

    bin/ci/wagon_nightly_stable.sh

### hitobito-[wagon]-rpm: RPM Build für einen Wagon

Läuft nach dem entsprechenden hitobito-[wagon]-nightly Job und erstellt ein RPM. Master oder Stable Branch.

Job gemäss RailsApplicationDeployment#Nightly_Build? , eine zusätzliche Umgebungsvariable mit dem RPM Namen muss definiert werden:

    RPM_NAME=[wagon]

Falls der Job für den Stable Branch läuft, muss die Umgebungsvariable

    RAILS_TRANSIFEX_DISABLED=true

gesetzt sein, damit keine Übersetzungen vom Transifex gepullt werden.

