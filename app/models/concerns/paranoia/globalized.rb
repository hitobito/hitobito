# encoding: utf-8

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

      alias_method_chain :destroy!, :translations
    end

    def destroy_with_translations!
      destroy_without_translations! && translations.destroy_all
    end

    module ClassMethods
      def translates(*columns)
        super(*columns)
        skip_callback :destroy, :before, '(has_many_dependent_for_translations)'
      end

      def list
        with_translations.
          order(:deleted_at, translated_label_column).
          uniq
      end
    end
  end
end