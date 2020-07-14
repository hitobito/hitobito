# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.
#
# Fetches people for which the user has write access via layer permissions or group permission.
class PersonWritables < PersonLayerWritables

  self.same_group_permissions = [:group_full]
  self.above_group_permissions = [:group_and_below_full]

end
