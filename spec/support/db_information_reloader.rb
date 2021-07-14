# frozen_string_literal: true

#  Copyright (c) 2020-2021, Stiftung für junge Auslandssschweizer. This file is part of
#  hitobito_sjas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sjas.

[
  Person,
  Group,
  Role
].each(&:reset_column_information)
