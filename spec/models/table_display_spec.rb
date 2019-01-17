require 'spec_helper'

describe TableDisplay do
  let(:leader) { people(:top_leader) }
  let(:group)  { groups(:top_layer) }
  let(:event)  { events(:top_event) }

  it 'initializes TableDisplay::Group for group parent' do
    subject = TableDisplay.for(leader, group)
    expect(subject).to be_instance_of(TableDisplay::People)
  end

  it 'initializes TableDisplay::Event for event parent' do
    subject = TableDisplay.for(leader, event)
    expect(subject).to be_instance_of(TableDisplay::Participations)
  end

  it 'allows resetting selected columns' do
    subject = TableDisplay.for(leader, event)
    subject.update(selected: %w(gender))
    subject.update(selected: [])
    expect(subject.selected).not_to be_present
  end

  context :with_permission_check do
    let(:member) { people(:bottom_member) }

    it 'yields if user has configured permission for attr on object' do
      subject = TableDisplay.for(leader, group)
      subject.permissions = { 'attr' => 'update' }
      expect { subject.with_permission_check('attr', leader) }.to raise_error(LocalJumpError)
    end

    it 'it handles object.field like syntax' do
      subject = TableDisplay.for(leader, group)
      subject.permissions = { 'attr' => 'update' }
      expect { subject.with_permission_check('obj.attr', leader) }.to raise_error(LocalJumpError)
    end

    it 'yields if no permission is configured for attr on object' do
      subject = TableDisplay.for(member, group)
      expect { subject.with_permission_check('attr', leader) }.to raise_error(LocalJumpError)
    end

    it 'does not yield if user does not have permission for attr on object' do
      subject = TableDisplay.for(member, group)
      subject.permissions = { 'attr' => 'update' }
      expect { subject.with_permission_check('attr', person) }.not_to raise_error(LocalJumpError)
    end

  end
end
