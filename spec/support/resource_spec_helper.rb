#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.
#
module ResourceSpecHelper
  extend ActiveSupport::Concern

  included do
    let(:ability) { Ability.new(person) }
    let(:person) { people(:top_leader) }
    let(:url_options) { { host: 'example.com' } }

    let(:context) do
      double(current_ability: ability, url_options: url_options).tap do |context|
        context.extend(Rails.application.routes.url_helpers)
      end
    end

    around do |example|
      RSpec::Mocks.with_temporary_scope do
        Graphiti.with_context(context) { example.run }
      end
    end
  end
end
