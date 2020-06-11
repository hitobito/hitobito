#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


class AccessGrantsController < CrudController
  def destroy
    super(location: access_grants_path)
  end

  def list_entries
    super.list.includes(:application).where(resource_owner_id: current_user.id)
  end

  def self.model_class
    Oauth::AccessGrant
  end

  private

  def authorize_class
    authorize!(:show, current_user)
  end
end
