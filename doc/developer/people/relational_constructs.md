# Relational constructs

## FamilyMember (Familienmitglieder)

- own model
- connects people into a family
- each family member has a kind, like `sibling`
- kind is i18n_enum, in core only `sibling`
- members joined by same `family_key`
- enabled by FeatureGate `people.family_members`
- is only active if no PeopleRelation entries present

## Household

- non active record model
- members joined by person#household_key
- brings people together in same household
- all household members share the same post address
- Household class is a ActiveModel::Model

see [Household Class](https://github.com/hitobito/hitobito/blob/master/app/models/household.rb)

## PeopleManager (youth wagon)

this is the Parent Access Feature (Elternzugang) which comes with the [youth wagon](https://github.com/hitobito/hitobito_youth/blob/master/app/models/people_manager.rb)
