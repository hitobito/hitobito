# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "propshaft/compiler"

# Sass copies url() into its output verbatim, so a stylesheet's own
# url('../../../fonts/x.woff2') is meaningless once dart-sass has bundled it
# into one file at a completely different depth - Propshaft would resolve it
# relative to app/assets/builds/<instance>/application.css and find nothing.
# Webpacker's css-loader used to resolve these against the *source* file, which
# is why every wagon writes them this way.
#
# All of our asset directories are registered flat (see
# config/initializers/assets.rb), so strip the escaping prefix together with
# the directory segment and let Propshaft's own CssAssetUrls compiler resolve
# what remains. Registered before it, so it sees the normalized urls.
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
