require 'spec_helper'
describe Event::ParticipationDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  include_context 'qualifier context'

  let(:quali_date)       { Date.new(2012, 10, 20) }
  let(:event_kind)       { event_kinds(:slk) }
  let(:decorator)        { Event::ParticipationDecorator.new(participation) }
  let(:participant_role) { Event::Role::Leader }
  let(:group)            { groups(:top_group) }

  { issue_action: [[nil, :active], [true, :inactive], [false, :active]],
    revoke_action: [[nil, :active], [true, :active], [false, :inactive]] }.each do |action, values|

    context "##{action}" do
      let(:node) { Capybara::Node::Simple.new(decorator.send(action, group)) }
      let(:icon) { node.find('i') }
      let(:link) { node.find('a') }

      values.each do |qualified, state|
        it "is #{state} if participation.qualified is #{qualified.nil? ? 'nil' : qualified}" do
          participation.update_column(:qualified, qualified)
          case state
          when :active then
            link.should be_present
            icon.should be_present
            icon[:class].should =~ /disabled/
          when :inactive then
            expect { link.should }.to raise_error Capybara::ElementNotFound
            icon.should be_present
            icon[:class].should_not =~ /disabled/
          end
        end
      end
    end

  end
end
