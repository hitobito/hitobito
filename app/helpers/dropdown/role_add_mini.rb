# encoding: utf-8
module Dropdown
  class RoleAddMini < RoleAdd
    attr_reader :person

    def initialize(template, group, person)

      # must be set BEFORE initialize, so we have it when building items
      @person = person

      super(template, GroupDecorator.new(group))

      # must be set AFTER initializer, so we override what intialize defined for us
      @label = 'Rolle hinzufügen'
      @carret = false
      @button_class = 'btn btn-mini'
    end

    private

    def link(entry)
      template.new_group_role_path(group, role: { type: entry[:sti_name], person_id: person.id }, redirect_to_person: true)
    end

  end
end
