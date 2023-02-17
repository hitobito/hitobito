module JsonApi
  class RoleAbility
    include CanCan::Ability

    def initialize(main_ability, people_scope)
      can :read, Role, person_id: permitted_people_ids(main_ability, people_scope)
    end

    private

    def permitted_people_ids(main_ability, people_scope)
      [].tap do |people_ids|
        people_scope.find_each do |person|
          people_ids << person.id if main_ability.can? :show_full, person
        end
      end
    end
  end
end
