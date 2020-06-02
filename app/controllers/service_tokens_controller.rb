#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ServiceTokensController < CrudController
  decorates :service_tokens, :service_token

  self.nesting = Group
  self.permitted_attrs = [
    :name,
    :description,
    :people,
    :people_below,
    :groups,
    :events,
    :invoices,
    :event_participations,
    :mailing_lists
  ]

  private

  def list_entries
    ServiceToken.where(layer: group).includes(:layer)
  end

  def return_path
    group_service_tokens_path(group)
  end

  alias group parent

  def authorize_class
    authorize!(:index_service_tokens, group)
  end

end
