# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'mail'
# Handle invalid charsets gracefully (e.g. windows-1258)
Mail::Ruby19.charset_encoder = Mail::Ruby19::BestEffortCharsetEncoder.new
