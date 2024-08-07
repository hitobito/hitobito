#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module I18nHelper
  # Translates the passed key by looking it up over the controller hierarchy.
  # The key is searched in the following order:
  #  - {controller}.{current_partial}.{key}
  #  - {controller}.{current_action}.{key}
  #  - {controller}.global.{key}
  #  - {parent_controller}.{current_partial}.{key}
  #  - {parent_controller}.{current_action}.{key}
  #  - {parent_controller}.global.{key}
  #  - ...
  #  - global.{key}
  def translate_inheritable(key, **variables) # rubocop:disable Metrics/MethodLength
    defaults = []
    unless controller.try(:skip_translate_inheritable)
      partial = @virtual_path ? @virtual_path.gsub(/.*\/_?/, "") : nil
      current = controller.class
      while current < ActionController::Base
        folder = current.controller_path
        if folder.present?
          defaults << :"#{folder}.#{partial}.#{key}" if partial
          defaults << :"#{folder}.#{action_name}.#{key}"
          defaults << :"#{folder}.global.#{key}"
        end
        current = current.superclass
      end
    end
    defaults << :"global.#{key}"
    key = defaults.shift
    options = variables.dup.reverse_merge(default: defaults)
    t(key, **options)
  rescue I18n::MissingTranslationData => e
    # Somehow the options are not set correctly in the exception which causes the message to be
    # missing this data relevant for understanding the problem. As a workaround we set the options
    # manually and re-raise the exception.
    e.instance_variable_set(:@options, options)
    raise e
  end

  alias_method :ti, :translate_inheritable

  # Translates the passed key for an active record association. This helper is used
  # for rendering association dependent keys in forms like :no_entry, :none_available or
  # :please_select.
  # The key is looked up in the following order:
  #  - activerecord.associations.models.{model_name}.{association_name}.{key}
  #  - activerecord.associations.{association_model_name}.{key}
  #  - global.associations.{key}
  def translate_association(key, assoc = nil, variables = {})
    primary =
      if assoc&.klass
        assoc_class_key = assoc.klass.model_name.to_s.underscore
        variables[:default] ||= [:"activerecord.associations.#{assoc_class_key}.#{key}",
          :"global.associations.#{key}"]
        owner_class_key = assoc.active_record.model_name.to_s.underscore
        "activerecord.associations.models.#{owner_class_key}.#{assoc.name}.#{key}"
      else
        "global.associations.#{key}"
      end
    t(primary, **variables)
  end

  alias_method :ta, :translate_association
end
