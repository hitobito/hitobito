# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Can not be a base class since graphiti seems to get confused about base classes
# for polymorphic relations.
# Thus, the json api type was always contactable and the relation couldn't be correctly mapped.
# Tried abstract_class = true, that didn't work either
module ContactableResource
  extend ActiveSupport::Concern

  included do
    attribute :label, :string
    attribute :public, :boolean

    attribute :contactable_id, :integer
    attribute :contactable_type, :string
  end

  def authorize_save(model)
    current_ability.authorize!(:show_details, model.contactable)
  end

  def index_ability
    IndexAbilityCache.index_ability(current_ability)
  end

  private

  # building the `JsonApi::ContactAbility` as currently implemented is very expensive.
  # we cache it so it can be used from the other instances of this resource.
  class IndexAbilityCache < ActiveSupport::CurrentAttributes
    attribute :cache

    def index_ability(main_ability)
      self.cache ||= {}
      self.cache[main_ability.user] ||= contact_ability(main_ability)
    end

    private

    def contact_ability(main_ability)
      JsonApi::ContactAbility.new(main_ability, people_scope(main_ability.user))
    end

    def people_scope(user)
      Person.accessible_by(PersonReadables.new(user))
    end
  end
end

