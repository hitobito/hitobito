# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Stampable
  extend ActiveSupport::Concern

  included do
    before_action  :set_stamper
    after_action   :reset_stamper
  end

  private

  def set_stamper
    Person.stamper = current_user
  end

  def reset_stamper
    Person.reset_stamper
  end
end
