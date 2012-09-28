# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer
#  person_id              :integer          not null
#  type                   :string(255)      not null
#  label                  :string(255)
#  additional_information :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'spec_helper'

describe Event::Participation do
  
  [Event, Event::Course].each do |event_type|
    event_type.participation_types.each do |part|
      context part do
        it "must have valid permissions" do
          # although it looks like, this example is about participation.permissions and not about Participation::Permissions
          Event::Participation::Permissions.should include(*part.permissions)
        end
      end
    end
  end
end
