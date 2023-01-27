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

    polymorphic_belongs_to :contactable do
      group_by(:contactable_type) do
        on(:Person)
      end
    end
  end

  def show_details?(model_instance)
    can?(:show_details, model_instance.contactable)
  end

  def show_details_or_public?(model_instance)
    show_details?(model_instance) || model_instance.public?
  end

  # we allow create/update/destroy if the user has `:show_details` permission on the contactable
  def authorize_save(model)
    current_ability.authorize!(:show_details, model.contactable)
  end
  alias_method :authorize_destroy, :authorize_save
end
