# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'dry-validation'

# See:
# - https://github.com/rubyconfig/config?tab=readme-ov-file#validation
# - https://dry-rb.org/gems/dry-validation/1.10/
class SettingsContract < Dry::Validation::Contract
  params do
    required(:people).schema do
      required(:inactivity_block).schema do
        required(:warn_after).maybe(:string)
        required(:block_after).maybe(:string)
      end
      required(:cleanup_cutoff_duration).schema do
        required(:regarding_current_sign_in_at).maybe(:string)
        required(:regarding_roles).maybe(:string)
        required(:regarding_event_participations).maybe(:string)
      end
    end
    required(:event).schema do
      required(:participations).schema do
        required(:delete_additional_information_after_months).maybe(:string)
      end
    end
  end

  [
    'people.inactivity_block.warn_after',
    'people.inactivity_block.block_after',
    'people.cleanup_cutoff_duration.regarding_current_sign_in_at',
    'people.cleanup_cutoff_duration.regarding_roles',
    'people.cleanup_cutoff_duration.regarding_event_participations',
    'event.participations.delete_additional_information_after_months'
  ].each do |path|
    rule(path) do
      next if values[path].nil? || valid_iso8601_duration?(values[path])

      key.failure('must be a valid ISO8601 duration string')
    end
  end

  private

  def valid_iso8601_duration?(value)
    ActiveSupport::Duration::ISO8601Parser.new(value).parse!
    true
  rescue ActiveSupport::Duration::ISO8601Parser::ParsingError, TypeError
    false
  end
end
