# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class HelpText::Loader
  attr_reader :controller_name, :action_name, :entry_class

  def initialize(controller_name, action_name, entry_class)
    @controller_name = controller_name
    @action_name = action_name
    @entry_class = entry_class
  end

  def find(key)
    key ||= "action.#{action_name}"
    help_texts.find { |ht| ht.key == key }
  end

  private

  def help_texts
    @help_texts ||= HelpText.includes(:translations)
                            .where(controller_name: controller_name, entry_class: entry_class)
                            .all
  end
end
