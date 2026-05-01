# frozen_string_literal: true

#  Copyright (c) 2020-2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# make sure our version of paper trail version is used (app/models/paper_trail/version.rb)
require_dependency 'paper_trail/version'

# We don't want paper_trail to create versions on touch events
# default is: [create update destroy touch]
# When we don't define a local skip option for a model, we want updated_at
# to be ignored per default. When a model adds own skip options,
# updated_at is not in the defaults anymore and has to be added
# manually if it should be skipped
PaperTrail.config.has_paper_trail_defaults = {
  on: %i[create update destroy],
  skip: %i[updated_at]
}

# We want to save the current to_s value of the item directly to the version
# This is used for displaying association texts in the logs
# e.g. Anhang foo wurde hinzugefügt
#
# If we don't save this label directly to the version and use paper trails reify to
# determine the label inside the logs, we run into an issue as soon as the label
# of an item is from a association and not directly on the item itself.
#
# This happens for attachments for example. The attachment label is the file name
# The file itself is a has_one_attached association that is not tracked by paper_trail
# So that association can't be reifyed. This results in log texts without labels as soon
# as the attachment get's deleted (Also older version of that attachment)
#
# This also improves performance when showing the log, since we don't have to reify all
# the items (well at least for versions from now on...)
ActiveSupport.on_load(:active_record) do
  def self.has_paper_trail(options = {})
    options[:meta] ||= {}

    options[:meta][:item_label] = lambda do |item|
      return nil if item.blank?

      if item.method(:to_s).arity != 0
        item.to_s(:long)
      else
        item.to_s
      end
    end

    super(options)
  end
end
