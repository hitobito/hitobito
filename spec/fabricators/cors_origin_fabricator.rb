#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: cors_origins
#
#  id               :bigint           not null, primary key
#  auth_method_type :string
#  origin           :string           not null
#  auth_method_id   :bigint
#
# Indexes
#
#  index_cors_origins_on_auth_method_type_and_auth_method_id  (auth_method_type,auth_method_id)
#  index_cors_origins_on_origin                               (origin)
#

Fabricator(:cors_origin) do
end
