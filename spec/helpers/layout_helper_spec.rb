# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe LayoutHelper do

  include CrudTestHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  describe '#header_logo_css' do

    it 'should find the logo directly on the visible group' do
      pending 'Not implemented'
      fail
    end

    it 'should find the logo on a parent group' do
      pending 'Not implemented'
      fail
    end

    it 'should return when not viewing a group' do
      expect(header_logo_css).to be nil
    end

    it 'should return when no logo is found' do
      pending 'Not implemented'
      fail
    end

  end
end
