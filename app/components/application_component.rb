# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ApplicationComponent < ViewComponent::Base

  private

  def stimulus_controller
    cls = respond_to?(:component_class) ? component_class : self.class
    cls.name.underscore.gsub('/', '--').tr('_', '-')
  end

  def stimulus_action(action, event: nil)
    prefix = [event, stimulus_controller].compact.join('->')
    [prefix, action].join('#')
  end

  def stimulus_value(name, value)
    [[[stimulus_controller, name, 'value'].join('-'), value]].to_h
  end

  def stimulus_param(name, value)
    [[[stimulus_controller, name, 'param'].join('-'), value]].to_h
  end
end
