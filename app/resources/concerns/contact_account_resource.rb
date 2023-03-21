# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Can not be a base class since graphiti seems to get confused about base classes
# for polymorphic relations.
# Thus, the json api type was always contactable and the relation couldn't be correctly mapped.
# Tried abstract_class = true, that didn't work either
module ContactAccountResource
  extend ActiveSupport::Concern

  included do
    attribute :label, :string
    attribute :public, :boolean

    attribute :contactable_id, :integer
    attribute :contactable_type, :string
  end

  def authorize_create(model)
    raise CanCan::AccessDenied unless model.contactable.is_a? Person
    super(model.contactable)
  end

  def authorize_update(model)
    raise CanCan::AccessDenied unless model.contactable.is_a? Person
    super(model.contactable) do |ability, model_from_db|
      ability.authorize!(:show_details, model_from_db)
    end
  end

  def authorize_destroy(model)
    raise CanCan::AccessDenied unless model.contactable.is_a? Person
    # Destroying a contact counts as updating the contactable
    destroy_ability.authorize!(:update, model.contactable)
    destroy_ability.authorize!(:show_details, model.contactable)
  end

  def index_ability
    JsonApi::ContactAccountAbility.new(current_ability)
  end
end
