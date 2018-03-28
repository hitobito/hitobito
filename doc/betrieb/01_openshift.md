# Hitobito @ Openshift

![Openshift Project](diagrams/ose3-rails.png)



## Composition Repository

Welcher Source-Code vom Core und den Wagons deployed wird, wird über die ose-composition repos definiert.

### Neu

Als erstes wird ein neues Repo auf Github erstellt. z.B. github.com/hitobito/ose_composition_generic

    NAME=myproject
    git clone https://github.com/hitobito/ose_composition_template ose_composition_$NAME
    git submodule update --init
    git remote set-url origin https://github.com/hitobito/ose_composition_$NAME.git

In diesem Repo gibt es standardmässig die Branches *production* und *devel*. Weitere Branches können natürlich nach Bedarf erstellt werden. Ersterer ist für stabile, produktive Umgebungen gedacht. Der *devel* ist für Continous Integration während der Entwicklung angedacht.

Nun werden die gewünschten Wagons hinzugefügt:

    git submodule add https://github.com/hitobito/hitobito_$MY_WAGON_REPO.git

Dann wechselt man in den Core und die Submodule und checked den gewünschten Stand/Branch aus. Danach erfolgt ein Commit im Composition Repo selber welcher die gewünschten Revisions der Submodules beinhaltet.

### Bestehendes Comp-Repo auschecken

Um ein bestehendes Compositon Repo auszuchecken:

    git clone --recurse-submodules https://github.com/hitobito/ose_composition_cevi.git -b production

## Neues Projekt

Als erstes wird ein neues Projekt auf Openshift angelegt:

    project=my-hitobito
    oc new-project $project




---- notes

* ose-rails-sphinx image docker hub
* containers (rails, delayed-job, sphinx, memcached, mysql, mysql-backup
* jenkins deployment job
