# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Passes
  class WalletDataProvider
    attr_reader :pass

    def initialize(pass)
      @pass = pass
    end

    def member_number
      pass.person.id.to_s.rjust(8, "0")
    end

    def member_name
      pass.person.full_name
    end

    # Additional text modules for Google Wallet passes.
    # Wagons override to return an array of hashes with keys :id, :header, :body.
    # The modules are appended to the core modules (member_name, member_number,
    # valid_until, description) and passed as textModulesData on the generic object.
    #
    # Each module is rendered as a labeled card in the pass view:
    #   header — small label shown above the value
    #   body   — larger value shown below the label
    #
    # Modules stack vertically beneath the hero image in the Google Wallet app.
    def extra_google_text_modules
      []
    end

    # Additional field groups for Apple Wallet passes (generic style).
    # Wagons override to return a hash with any combination of the keys
    # :primaryFields, :secondaryFields, :auxiliaryFields, :backFields,
    # each containing an array of field hashes with :key, :label, :value.
    # Fields are appended (concat) to the core fields in the same group.
    #
    # Layout on the pass front (generic style):
    #
    #   +---------------------------------------+
    #   |  logo.png               thumbnail.png |
    #   |                                       |
    #   |  primaryFields   (large, most visible)|
    #   |  secondaryFields (smaller row)        |
    #   |  auxiliaryFields (smaller row)        |
    #   |                                       |
    #   |          [ barcode ]                  |
    #   +---------------------------------------+
    #
    # backFields are shown on the flip side when the user taps the info button.
    # Within each row, fields are placed left to right in array order;
    # each row fits at most 3 fields before truncating.
    def extra_apple_fields
      {}
    end

    # Additional image files to include in the Apple .pkpass bundle.
    # Wagons override to return a hash mapping filenames to binary data.
    # The role of each image is determined solely by its filename, Apple's
    # PassKit spec defines fixed slot names:
    #
    #   Filename                              Role
    #   ------------------------------------  ----------------------------------------
    #   icon.png / icon@2x.png                App icon (already provided by base service)
    #   logo.png / logo@2x.png                Top-left logo (already provided)
    #   thumbnail.png / thumbnail@2x.png      Right-side thumbnail (already provided)
    #   strip.png / strip@2x.png              Full-width image behind primary fields
    #   background.png / background@2x.png    Full-card background image
    #   footer.png / footer@2x.png            Image above the barcode
    def extra_apple_images
      {}
    end
  end
end
