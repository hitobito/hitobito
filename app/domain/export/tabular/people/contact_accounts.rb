#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  module ContactAccounts
    class << self
      # Generic "model + value" key/human formatters. Used both for
      # ContactAccountCategory-based columns (value is a category's #key/#to_s)
      # and, unrelatedly, for QualificationKind columns (value is a
      # qualification_kind's id/label) -- callers always pass a real,
      # non-blank value.
      def key(model, value)
        :"#{model.model_name.to_s.underscore}_#{value.to_s.downcase}"
      end

      def human(model, value)
        "#{model.model_name.human} #{value}"
      end

      # ContactAccountCategory rows for each of the given models, indexed by #key
      # (see .key above). Shared by PersonRow (built standalone, e.g. in specs)
      # and Export::Tabular::People::PeopleAddress (shared once across a whole
      # export, see PeopleAddress#row_for).
      def categories_by_key(models, contactable_type)
        models.index_with do |model|
          ContactAccountCategory.for(model.sti_name, contactable_type)
            .index_by { |category| key(model, category.key) }
        end
      end
    end
  end
end
