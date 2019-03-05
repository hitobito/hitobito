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

    subject { TableDisplay.for(member, group) }
    before  { TableDisplay.register_permission(Person, :update, :attr) }
    after   { TableDisplay.class_variable_set('@@permissions', {}) }

    context :on_leader do
      it 'yields if accessing unprotected attr' do
        expect { subject.with_permission_check('other_attr', leader) }.to raise_error(LocalJumpError)
      end

      it 'noops if accessing protected attr' do
        expect { subject.with_permission_check('attr', leader) }.not_to raise_error(LocalJumpError)
      end
    end

    context :on_member do
      it 'yields if accessing unprotected attr' do
        expect { subject.with_permission_check('other_attr', member) }.to raise_error(LocalJumpError)
      end

      it 'yields if accessing protected attr' do
        expect { subject.with_permission_check('attr', members) }.not_to raise_error(LocalJumpError)
      end
    end

    context :with_navigation do
      subject { TableDisplay.for(member, group) }

      it 'noops if accessing protected attr' do
        participation = Event::Participation.new(person: leader)
        expect { subject.with_permission_check('person.attr', participation) }.not_to raise_error(LocalJumpError)
      end
    end
  end
end
