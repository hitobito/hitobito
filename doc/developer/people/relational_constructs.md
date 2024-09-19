# Relational constructs

## FamilyMember (Familienmitglieder)

- own model
- connects people into a family
- each family member has a kind, like `sibling`
- kind is i18n_enum, in core only `sibling`
- members joined by same `family_key`
- enabled by FeatureGate `people.family_members`
- is only active if no PeopleRelation entries present

## PeopleRelation (Beziehungen)

- own model
- relates two people together
- one person is called :head, the other :tail
- person model: `has_many :relations_to_tails, class_name: "PeopleRelation"`
- active when PeopleRelation.kind_opposites present (class_attribute, set in wagon.rb)

see [PeopleRelation Model Class](https://github.com/hitobito/hitobito/blob/master/app/models/people_relation.rb)

## Household

- non active record model
- members joined by person#household_key
- brings people together in same household
- all household members share the same post address
- Household class is a ActiveModel::Model

see [Household Class](https://github.com/hitobito/hitobito/blob/master/app/models/household.rb)

## PeopleManager (youth wagon)

this is the Parent Access Feature (Elternzugang) which comes with the [youth wagon](https://github.com/hitobito/hitobito_youth/blob/master/app/models/people_manager.rb)
