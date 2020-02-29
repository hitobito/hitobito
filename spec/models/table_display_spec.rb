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
    before  do
      TableDisplay.register_permission(Person, :update, :attr)
      subject.selected = %w(other_attr attr)
    end
    after   { TableDisplay.class_variable_set('@@permissions', {}) }

    context :on_leader do
      it 'yields if accessing unprotected attr' do
        expect { |b| subject.with_permission_check(leader, 'other_attr', &b) }.to yield_with_args(leader, 'other_attr')
      end

      it 'noops if accessing protected attr' do
        expect { |b| subject.with_permission_check(leader, 'attr', &b) }.not_to yield_control
      end
    end

    context :on_member do
      it 'yields if accessing unprotected attr' do
        expect { |b| subject.with_permission_check(member, 'other_attr', &b) }.to yield_with_args(member, 'other_attr')
      end

      it 'yields if accessing protected attr' do
        expect { |b| subject.with_permission_check(member, 'attr', &b) }.to yield_with_args(member, 'attr')
      end
    end
  end
end
