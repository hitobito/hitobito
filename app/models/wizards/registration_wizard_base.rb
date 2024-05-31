module Wizards
  class RegistrationWizardBase < Wizard
    attribute :group
    attribute :person
    attribute :role

    validates_presence_of :group, :person, :role, if: :last_step?

    def initialize(current_step:, current_ability: nil, **params)
      super(current_ability:, current_step:, **params)
      initialize_wizard

      # TODO: properly prevent the wizard to be used if self_registration is not active
      # The group might not be initialized yet on the first page
      raise ArgumentError, 'group.self_registration_active? must be true' unless group.nil? || group.self_registration_active?
    end

    def initialize_wizard
      # noop, override in subclass if required
    end
  end
end
