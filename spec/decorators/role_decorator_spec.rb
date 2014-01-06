# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe RoleDecorator, :draper_with_helpers do

  let(:role) { roles(:top_leader) }
  let(:decorator) {  RoleDecorator.new(role) }
  subject { decorator }

  its(:flash_info) { should eq '<i>Leader</i> für <i>Top Leader</i> in <i>TopGroup</i>' }

end
