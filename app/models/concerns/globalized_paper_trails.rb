#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Creates paper trails on all translated attributes of a model
# Add after inital has_paper_trail and Globalized module
module GlobalizedPaperTrails
  extend ActiveSupport::Concern

  included do
    # Since the default attribute names dont exist on the table, ActiveRecord treats them as changes
    # PaperTrail always checks saved_changes and changes which leads to paper trail creating
    # versions when there's no changes at all (nil to "" or nil to nil).
    #
    # To prevent issues of having paper trail versions when we don't want/need them, we add all
    # translated attributes to the skip list and create own paper trail versions on the
    # translation classes
    paper_trail_options[:skip] |= translated_attribute_names.map(&:to_s)

    translation_class.class_eval do
      # To be able to use the same translation key for all classes we override the i18n_key
      # This is used that we don't have to add event/translations, invoice/translations and multiple
      # translation keys resulting in the same translation.
      def self.model_name
        super.tap do |name|
          def name.i18n_key
            "translation"
          end
        end
      end

      has_paper_trail meta: {main_id: ->(t) {
        t.send(reflect_on_association(:globalized_model).foreign_key)
      },
                             main_type: reflect_on_association(:globalized_model).klass.sti_name},
        skip: [:created_at, :updated_at]

      # This is used to display in log what language record actually changed. Currently those
      # values are just the strings from settings.yml, so the log does not display translated
      # language names
      def to_s(format = :default)
        Settings.application.languages[locale]
      end
    end
  end
end
