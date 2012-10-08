# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

require 'spec_helper'

describe Event::Role do
  
  [Event, Event::Course].each do |event_type|
    event_type.role_types.each do |part|
      context part do
        it "must have valid permissions" do
          # although it looks like, this example is about participation.permissions and not about Participation::Permissions
          Event::Role::Permissions.should include(*part.permissions)
        end
      end
    end
  end
end
