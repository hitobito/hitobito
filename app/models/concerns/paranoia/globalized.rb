#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Paranoia
  module Globalized
    extend ActiveSupport::Concern

    include ::Globalized

    included do
      acts_as_paranoid
      extend Paranoia::RegularScope

      prepend Paranoia::Globalized::Translation
    end

    module Translation
      def really_destroy!
        super && translations.destroy_all
      end
    end

    module ClassMethods
      def list
        select(column_names + ["#{table_name}.#{translated_attribute_names.first}"]).from(
          with_translations.select("#{table_name}.*", translated_label_column)
          .distinct_on(:id).unscope(:order), table_name
        ).with_translations.order("#{table_name}.#{translated_attribute_names.first}")
      end
    end
  end
end
