# CI/CD

* Tests werden auf GitHub als GitHub Actions ausgeführt

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

## Wagon-Tests bei Core-Änderungen

Eine Änderung am Core kann die Tests jedes Wagons brechen. Deshalb lässt
[run-all-wagon-tests.yml](https://github.com/hitobito/hitobito/blob/master/.github/workflows/run-all-wagon-tests.yml)
die Tests aller Wagons gegen den geänderten Core laufen.

* Welche Wagons getestet werden, wird nicht konfiguriert, sondern ermittelt: alle nicht archivierten
  `hitobito_*`-Repositories der Organisation, abzüglich der Variable `WAGON_TESTS_SKIP_WAGONS`.
* Getestet wird jeder Commit auf dem `master` Branch, und auf einem Pull Request auf Anfrage: Der
  Trigger dafür ist das Label `run-wagon-tests!`. Der Trigger auf jeden Push eines Pull Requests ist
  bewusst deaktiviert, er hat die Runner zu oft belegt.
* Der Job "All wagon tests are green" fasst die ganze Matrix zu einem einzelnen Check zusammen, auf
  den sich der Branch Protection Rule abstützt. Er läuft auch dann, wenn die Matrix gar nicht
  gebaut wurde (z.B. weil ein anderes Label gesetzt wurde), und meldet in dem Fall das Resultat, das
  derselbe Commit zuletzt erreicht hat.

## Wagon-Tests bei Änderungen an einem Dependency-Wagon

Manche Wagons bauen auf einem anderen Wagon auf (`hitobito_bdp` und `hitobito_dpsg` auf
`hitobito_pfadi_de`, `hitobito_pbs` und weitere auf `hitobito_youth`). Eine Änderung an so einem
Dependency-Wagon kann die abhängigen Wagons genauso brechen wie eine Änderung am Core. Dafür gibt es
dasselbe eine Stufe weiter unten: `run-dependent-wagon-tests.yml` im Dependency-Wagon.

* Der Workflow selber liegt im Dependency-Wagon, die Bestandteile im Core:
  [find-dependent-wagons.yml](https://github.com/hitobito/hitobito/blob/master/.github/workflows/find-dependent-wagons.yml)
  liefert die Matrix, `wagon-tests.yml` testet jeden Wagon darin, und
  [dependent-wagon-tests-green.yml](https://github.com/hitobito/hitobito/blob/master/.github/workflows/dependent-wagon-tests-green.yml)
  fasst das Resultat zusammen.
* Im Core wird dabei nichts getriggert, damit Core-Änderungen nicht dieselben Wagon-Tests ein
  zweites Mal auslösen.
* Welche Wagons abhängig sind, wird wiederum ermittelt statt konfiguriert: Es sind alle Wagons,
  deren Gemspec ein `add_dependency` auf den Dependency-Wagon enthält. Ein neuer abhängiger Wagon
  wird also ohne Anpassung am Workflow getestet.
* Getestet wird jeder Commit auf dem Hauptbranch des Dependency-Wagons, und auf einem Pull Request
  auf Anfrage – mit demselben Label `run-wagon-tests!` wie in der Core-Pipeline.
* Der zusammenfassende Check heisst hier "All dependent wagon tests are green" und funktioniert
  gleich wie derjenige der Core-Pipeline.
