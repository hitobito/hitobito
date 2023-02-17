module JsonApi
  class ContactAbility
    include CanCan::Ability

    CONTACT_MODELS = [
      AdditionalEmail,
      PhoneNumber,
      SocialAccount
    ]

    def initialize(main_ability, people_scope)
      @main_ability = main_ability
      @people_scope = people_scope
      
      # allow reading all contacts that are public
      can :read, CONTACT_MODELS, public: true
      # allow reading contacts of people on which the user has show_details permissions
      can :read, CONTACT_MODELS, contactable_type: 'Person', contactable_id: permitted_people_ids(main_ability, people_scope)
      # TODO: implement rules for Group contactables (and any other existing contactable classes)
    end

    private

    def permitted_people_ids(main_ability, people_scope)
      [].tap do |people_ids|
        people_scope.find_each do |person|
          people_ids << person.id if main_ability.can? :show_details, person
        end
      end
    end
  end
end
