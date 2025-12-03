# ADR-012 Einheitliche Namespaces

Status: **Vorschlag**

Entscheid: **Entscheidung noch offen**

## Kontext

Bisher wurden Namespaces in Singular und in Plural benannt.
Zudem wurden auch Klassen als Namespaces verwendet (z.B. ActiveRecord Model Klassen).

Dadurch ist es vielfach nicht eindeutig ersichtlich, ob ein Namespace ein Modul oder eine Klasse ist. 
Zudem ist es häufig nicht klar, unter welchem Namespace eine neue Klasse erstellt werden soll. 

## Empfehlung

* Viele Namespaces sind von Model Namen abgeleitet. Diese sollen mit einem Namen im Plural benannt werden. 
* Namespaces sollen entsprechend möglichst Module sein, keine Klassen.
* Ausnahme bilden Models, welche zu einem Hauptmodell gehören (z.B. `Event::Date`) oder STI Models (z.B. `Group::Kanton`). 
