# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require 'benchmark'

N = 1_000

LOAD_USER_TIME = 1.0
INIT_ABILITY_TIME = 1.5

describe Ability, performance: true do

  def measure(max_time, &block)
    Benchmark.bm(12) do |x|
      ms = x.report(RSpec.current_example.description) do
        N.times(&block)
      end

      if ms.total > max_time
        puts "!!! TOOK LONGER THAN #{max_time} !!!"
      end
    end
  end

  it 'load user' do
    measure(LOAD_USER_TIME) do
      Person::PreloadGroups.for(people(:top_leader))
    end
  end

  it 'init ability' do
    user = people(:top_leader)
    Person::PreloadGroups.for(user)

    measure(INIT_ABILITY_TIME) do
      Ability.new(user)
    end
  end

end
