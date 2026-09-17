# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "propshaft/compiler"

# Sass copies url() into its output verbatim, so a stylesheet's own
# url('../../../fonts/x.woff2') is meaningless once dart-sass has bundled it
# into one file at a completely different depth. But relative url() calls work
# well in IDEs and are the historically established pattern in hitobito wagons.
# This propshaft compiler adds support for such relative urls.
class Hitobito::RelativeAssetUrls < Propshaft::Compiler
  # Only directories we actually register as flat asset roots, so this can
  # never touch an unrelated relative url.
  ASSET_DIRS = %w[fonts images webfonts].freeze

  # Wagons spell the way up to their own app/assets either as
  # "../../../fonts/x.woff2" or as "../../../../assets/images/x.png", so the
  # "assets/" segment is optional.
  ASSET_URL_PATTERN = %r{url\(\s*(['"]?)(?:\.\./)+(?:assets/)?(?:#{Regexp.union(ASSET_DIRS)})/}

  def compile(asset, input)
    input.gsub(ASSET_URL_PATTERN) { "url(#{$1}" }
  end
end
