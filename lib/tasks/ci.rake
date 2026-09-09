# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :ci do
  desc "Check for pending specs"
  task check_pending: :environment do
    require "rspec/core"
    args = "-f json --dry-run spec"
    options = RSpec::Core::ConfigurationOptions.new(args.split)
    out = StringIO.new
    RSpec::Core::Runner.new(options).run($stderr, out)
    examples = JSON.parse(out.string)["examples"]
    if examples.empty?
      puts JSON.pretty_generate(out.string)
      abort("General failure")
    end
    pending = examples.select { |ex| ex["status"] == "pending" }
    abort("Failing because of pending specs\n\n#{JSON.pretty_generate(pending)}") if pending.any?
  end
end
