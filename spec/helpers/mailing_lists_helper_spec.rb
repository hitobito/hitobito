require 'spec_helper'

describe MailingListsHelper do
  
  include StandardHelper
  include LayoutHelper
  
  let(:entry) { mailing_lists(:leaders) }
  let(:current_user) { people(:top_leader) }
  
  describe '#button_toggle_subscription' do
    
    it "with subscribed user shows 'Anmelden'" do
      sub = entry.subscriptions.new
      sub.subscriber = current_user
      sub.save!
      
      @group = entry.group
      button_toggle_subscription.should =~ /Abmelden/
    end
        
    it "with not subscribed user shows 'Abmelden'" do
      @group = entry.group
      button_toggle_subscription.should =~ /Anmelden/
    end
  end
  
end
