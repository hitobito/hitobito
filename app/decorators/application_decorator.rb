# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ApplicationDecorator < Draper::Decorator
  include Translatable

  delegate_all
  delegate :to_s, to: :model
  delegate :can?, :content_tag, :safe_join, :current_user, :current_service_token, to: :h

  ## custom access to model class
  # model_class from draper does not play well with STI
  def klass
    model.class
  end

  def used_attributes(*attributes)
    attributes.select { |name| model.used_attributes.include?(name) }.map(&:to_s)
  end

  def used?(attribute)
    used_attributes(attribute).each { |_| yield }
  end

  def updated_info
    modification_info(updated_at, updater)
  end

  def created_info
    modification_info(created_at, creator)
  end

  def deleted_info
    modification_info(deleted_at, deleter)
  end

  def archived_info
    modification_info(archived_at, nil)
  end

  private

  def modification_info(at, person)
    return '' if at.nil?

    html = I18n.localize(at, format: :date_time)
    if person.present?
      html << ' '
      html << h.link_to_if(can?(:show, person), person.to_s, h.person_path(person.id))
    end
    h.sanitize(html)
  end

end
