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