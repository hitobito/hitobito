# == Schema Information
#
# Table name: cors_origins
#
#  id               :bigint           not null, primary key
#  auth_method_type :string(255)
#  auth_method_id   :bigint
#  origin           :string(255)      not null
#
#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:cors_origin) do
end
