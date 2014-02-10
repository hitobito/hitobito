module Export::Csv::Groups
  class Subgroups < Export::Csv::Base

    EXCLUDED_ATTRS = %w(lft rgt contact_id)

    self.model_class = Group

    def initialize(group)
      super(group.self_and_descendants.without_deleted.includes(:contact))
    end

    def attributes
      (model_class.column_names - EXCLUDED_ATTRS).collect(&:to_sym)
    end

  end
end