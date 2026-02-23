#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  module ContactAccounts
    class << self
      def key(model, label)
        :"#{model.model_name.to_s.underscore}_#{label_or_default(label, model).downcase}"
      end

      def human(model, label)
        "#{model.model_name.human} #{label_or_default(label, model)}"
      end

      def free_text_key(model)
        :"#{model.model_name.to_s.underscore}_free_text"
      end

      def free_text_human(model)
        label_text = I18n.t("activerecord.attributes.contact_account.free_text_label")
        "#{model.model_name.human(count: :other)} #{label_text}"
      end

      def predefined_labels(model)
        contact_account_settings(model)&.predefined_labels || []
      end

      def free_text_label_enabled?(model)
        contact_account_settings(model)&.free_text_label&.enabled
      end

      private

      def contact_account_settings(model)
        Settings.send(model.table_name.singularize)
      end

      def label_or_default(label, model)
        label || predefined_labels(model).first
      end
    end
  end
end
