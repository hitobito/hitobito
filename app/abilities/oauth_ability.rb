#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class OauthAbility < AbilityDsl::Base

  on(Oauth::Application) do
    class_side(:index).if_admin

    permission(:admin).may(:manage).all
  end

  on(Oauth::AccessGrant) do
    class_side(:index).if_admin

    permission(:admin).may(:manage).all
    permission(:any).may(:destroy).own_access_grants
  end

  on(Oauth::AccessToken) do
    class_side(:index).if_admin
    permission(:admin).may(:manage).all
  end

  def own_access_grants
    subject.resource_owner_id == user.id
  end

end
