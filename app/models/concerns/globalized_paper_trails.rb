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
    sync_paper_trail_skip_attributes
    paper_trail_options[:skip] |= (translated_attribute_names.map(&:to_s) +
                                   globalize_attribute_names.map(&:to_s))

    translation_class.class_eval do
      has_paper_trail meta: {main_id: ->(t) {
        t.send(reflect_on_association(:globalized_model).foreign_key)
      },
                             main_type: reflect_on_association(:globalized_model).klass.sti_name},
        skip: [:created_at, :updated_at]

      # This is used to display in log what language record actually changed. Currently those
      # values are just the strings from settings.yml, so the log does not display translated
      # language names
      def to_s(format = :default)
        locale.to_s
      end
    end
  end

  class_methods do
    # Resync paper trail skip options after another translated attribute
    # may have been added to a wagon
    def translates(...)
      super

      sync_paper_trail_skip_attributes
    end

    def sync_paper_trail_skip_attributes
      return unless respond_to?(:paper_trail_options)

      paper_trail_options[:skip] |= (translated_attribute_names.map(&:to_s) +
                                     globalize_attribute_names.map(&:to_s))
    end
  end
end
