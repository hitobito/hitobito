# ADR-012 Einheitliche Namespaces

Status: **Vorschlag**

Entscheid: **Entscheidung noch offen**

## Kontext

Bisher wurden Namespaces in Singular und in Plural benannt.
Zudem wurden auch Klassen als Namespaces verwendet (z.B. ActiveRecord Model Klassen).

Dadurch ist es vielfach nicht eindeutig ersichtlich, ob ein Namespace ein Modul oder eine Klasse ist. 
Zudem ist es häufig nicht klar, unter welchem Namespace eine neue Klasse erstellt werden soll. 

## Empfehlung

* Es sollen möglichst nur Module als Namespaces verwenden. In Klassen sollen nur weitere Klassen genestet sein, wenn diese ausschiesslich innerhalb der "Namespace-Klasse" verwendet werden ("private" Klassen).
* Namespaces welche thematisch zu einem Model gehören, sollen mit pluralisiertem Namen des Models benannt werden (z.B. `Group` → `Groups`).
