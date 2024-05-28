# CI/CD

* Tests werden auf GitHub als GitHub Actions ausgeführt
* Deployment bei Puzzle geschieht via Jenkins.

# Test-Pipelines

## Core

Gebaut wird jeder Commit, es läuft ein [GitHub-Workflow](https://github.com/hitobito/hitobito/blob/master/.github/workflows/tests.yml).

## Wagon

Alle Wagons verwenden denselben Workflow: [Template](https://github.com/hitobito/hitobito/blob/master/.github/workflows/wagon-tests.yml), [Integration am Beispiel PBS](https://github.com/hitobito/hitobito_pbs/blob/master/.github/workflows/tests.yml).

Gebaut wird

* Jeder Commit
* Einmal nächtlich, um mitzubekommen, wenn Änderungen am Core die Wagon-Tests fehlschlagen lassen.

### Entscheid: Nightlies vs getriggerte Wagon-Builds

Es wäre eleganter, wenn Commits im Core den Rebuild der Wagons triggern. Aus Security-Überlegungen ist das nicht so umgesetzt.

Hintergrund: Damit die Core-Pipeline Wagon-Builds triggern kann, benötigt sie entsprechende Berechtigungen. Das wird mittels _Personal Access Token_ eines Funktionsusers (ein GitLab-User, der nur diesem Zweck dient) realisiert. Der Funktionsuser braucht Schreibberechtigungen auf alle Wagon-Repos. Das Personal Access Token kann aber potentiell von externen Contributors im Core-Repo ausgelesen werden.
