# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Wizards render their form next to an aside, so the label needs a bigger share
# of the row than on a form spanning the full content width.
class WizardFormBuilder < StandardFormBuilder
  def self.label_class
    "col-md-3 col-lg-4"
  end
end
