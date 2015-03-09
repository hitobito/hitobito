# encoding: utf-8

#  Copyright (c) 2012-2015, Puzzle ITC Gmbh. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SphinxIndexJob < RecurringJob

  run_every Settings.sphinx.index.interval.minutes

  def perform_internal
    ThinkingSphinx::RakeInterface.new.index
  end
end
