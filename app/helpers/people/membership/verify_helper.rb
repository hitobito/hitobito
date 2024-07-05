# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module People::Membership::VerifyHelper
  def membership_verify_logo
    logo = Settings.application.membership_verify_logo
    if logo
      wagon_image_pack_tag(logo.image, alt: Settings.application.name)
    else
      header_logo
    end
  end
end
