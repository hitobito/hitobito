# Release einer neuen Version

Um eine neue Version von Hitobito auf dem Produktionssystem, muss der
gewünschte Code in einem Composition-Repo per Tag markiert und im Branch
`production` gespeichert sein. Bei einem Release sollten die Übersetzungen
aktuell sein und die Versionsnummer angepasst werden.

Wir lösen das aktuell mit Github Actions, welche eine neue Version vergeben und
dann Übersetzungen holen und die erforerlichen Code-Repositories anpassen.

Grundsätzlich sollten Releases aus einem Composition-Repo heraus gemacht
werden, da hier alle definierten/benötigten Wagons verfügbar sind.

## Kontextabgrenzung

Vor dem Vorbereiten des Release muss aller relevanter Applikationscode in den
Repositories committed und gepusht sein.

Nach dem Vorbereiten des Release kann aus dem Composition-Repo dann ein Image
gebaut werden, welches dann auf der Betriebsplatform installiert werden kann.
Dieser Schritt wird aktuell mit Jenkins gemacht und ist nicht Bestandteil der
Release-Vorbereitung.

# Ablauf

## automatisierter Ablauf

Jedes Composition-Repo hat einen Workflow, welcher den zentralen
[Reusable Workflow](../../.github/workflows/prepare-version.yml) aufruft, um
einen Release komplett vorzubereiten. Dieser Workflow kann über
`gh workflow run "Prepare Release"` oder das Github WebUI gestartet werden. Dem
Workflow im Composition-Repo werden keine Parameter übergeben.

Es wird der Branch `master` von allen Repos als nächste Version vorbereitet.
Die Versionsnummer ist aktuell die nächste Patch-Version.

## manueller Ablauf

Um mehr Kontrolle über den Ablauf zu haben, kann der Release auch manuell
vorbereitet werden. Hierbei hilft das [Release-Script](../../bin/release).
Grundsätzlich sind das die folgenden Schritte:

1. In das Composition-Repo wechseln, dass man releasen möchte.
2. Code auf den gewünschten Stand bringen, die kann ein beliebiger Branch, also
	 auch ein Hotfix-Branch, sein.
3. Versionsnummer ausdenken oder vorschlagen lassen:

	```bash
	hitobito/bin/release suggest-version patch
	```

4. Alle nötigen Repositories mit aktuellen Übersetzungen versehen und die
	 Versionsnummer in der `VERSION` oder `lib/hitobito_*/version.rb` anpassen,
	 taggen, committen und pushen. Weiterhin das gesamte Composition-Repo
	 committen, taggen und pushen.

	```bash
	wagon='generic'
	version=$(hitobito/bin/release suggest-version patch)
	hitobito/bin/release composition $wagon $version --dry-run
	```

5. das gleiche Command nochmal ohne `dry-run` laufen lassen, wenn einem der
	 Output gefällt.

## Hotfixes

Manuelle Hotfixes sind nach wie vor möglich, siehe [oben](#manueller-ablauf).

Beim nächsten Release mit dem Workflow wird die Patchversion erhöht. Da
Hotfixes eine Version mit einer weiter Stelle verwenden, ist der Wechseln von
Hotfix zu regulärem Release problemelos möglich.

## Workflow via CLI starten

Um Klickarbeit zu verhindern, kann man auch mit der github-cli den Release vorbereiten:

```bash
# change into the to-be-release composition repo first
gh workflow run "Prepare Release" && sleep 2 \
&& export last_run_id=$(gh run list --workflow=prepare-release.yml -L1 --json databaseId -q '.[].databaseId') \
&& (gh run watch $last_run_id --exit-status || gh run view $last_run_id --web) \
&& unset last_run_id
```

Dies startet den Workflow und zeigt im Terminal den aktuellen Stand an. Wenn
der Workflow fehlschlägt, wird es im Browser geöffnet.

# Ausblick und Hinweise

Die verwendete Version kann auf `current-month` umgestellt werden. Dies ändert
den Patchlevel von einer normal aufsteigende Ganzzahl zu einem eher sprechenden
Konstrukt im Format YYYY-MM.

Wenn eine Version verwendet wird, für die schon ein Tag gesetzt ist, wird der
damit referenzierte Codestand für das Release verwendet. So werden unnötige
Commits vermieden und parallele Releases ermöglicht. Dieses Feature ist
grundsätzlich auch für Patchversionen eingebaut, entfaltet aber erst mit einer
Monatsversion die volle Wirksamkeit.

Man könnte das Release-Script so erweitern, das weitere Versionsschemata
(aktuelle Woche?), Release-Modi (ohne composition-repo wagons direkt
auflisten?) oder beides (bewusster Hotfix, der einen bestimmten Patch enthält?)
unterstützt. Aktuell ist kein guter Use-Case vorhanden, das zu tun.

# Links

- [Shared Workflow](../../.github/workflows/prepare-version.yml)
- [Release-Script](../../bin/release)
