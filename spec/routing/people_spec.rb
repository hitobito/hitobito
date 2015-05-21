# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'people routes' do

  it do
    expect({ get: '/people/42' }).
    to route_to(
      controller: 'people',
      action: 'show',
      id: '42'
    )
  end

end
