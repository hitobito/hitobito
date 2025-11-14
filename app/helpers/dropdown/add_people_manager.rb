module Dropdown
  # It's safe to use instance variables here because they
  # are encapsulated within their own class.
  # rubocop:disable Rails/HelperInstanceVariable
  class AddPeopleManager < Base
    delegate :can?, :cannot?, :new_person_manager_path, :new_person_managed_path, to: :template
    delegate :managers, :manageds, to: "@person"

    def initialize(template, person)
      super(template, template.ti(:"link.add"), :plus)
      @person = person
      init_items
    end

    def to_s
      return "" if @items.none?
      return single_action_button if @items.one?

      super
    end

    private

    def single_action_button
      template.action_button(@items.first.label, @items.first.url, :plus, class: "btn-sm")
    end

    def init_items # rubocop:todo Metrics/CyclomaticComplexity
      add_assign_manager_item if create_manager? && manageds.none?
      add_assign_managed_item if create_managed? && managers.none?
      add_create_managed_item if create_new_managed? && managers.none?
    end

    def add_assign_manager_item
      add_item(t(:assign_manager_person_button), new_person_manager_path(@person))
    end

    def add_assign_managed_item
      add_item(t(:assign_managed_person_button), new_person_managed_path(@person))
    end

    def add_create_managed_item
      add_item(t(:create_managed_person_button), new_person_managed_path(@person, create: true))
    end

    def create_managed?
      can?(:create_managed, PeopleManager.new(manager: @person)) && can?(:lookup_manageds, Person)
    end

    def create_manager?
      can?(:create_manager, PeopleManager.new(managed: @person))
    end

    def create_new_managed?
      cannot?(:lookup_manageds, Person) &&
        FeatureGate.enabled?("people.people_managers.self_service_managed_creation")
    end

    def t(key)
      I18n.t(key, scope: [:people_managers])
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
