# encoding: UTF-8
require 'spec_helper'
describe RoleDecorator do

  let(:role) { roles(:top_leader)}
  let(:subject) { RoleDecorator.new(role) }

  its(:flash_info) { should eq "<i>Rolle</i> für <i>Foo Bar</i> in <i>TopGroup</i>" }
end
