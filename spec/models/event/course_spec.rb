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
