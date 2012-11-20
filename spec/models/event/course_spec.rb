# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#  application_contact_id :integer
#

require 'spec_helper'

describe Event::Course do
  
      
  subject do
    Fabricate(:course, groups: [groups(:top_group)] )
  end
  
  context "#qualification_date" do
    before do
      add_date("2011-01-20")
      add_date("2011-02-15")
      add_date("2011-01-02")
    end
    
    its(:qualification_date) { should == Date.new(2011, 02, 20) }
  end
  
  def add_date(start_at, event = subject)
    start_at = Time.zone.parse(start_at)
    event.dates.create(start_at: start_at, finish_at: start_at + 5.days)
  end
end
