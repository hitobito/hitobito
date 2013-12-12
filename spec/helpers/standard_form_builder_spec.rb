# encoding: utf-8

require 'spec_helper'

describe 'StandardFormBuilder' do

  include StandardHelper
  include ListHelper
  include CrudTestHelper
  include LayoutHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  let(:entry) { CrudTestModel.first }
  let(:form)  { StandardFormBuilder.new(:entry, entry, self, {}, lambda { |form| form }) }

  describe '#input_field' do

    { name: :string_field,
     password: :password_field,
     remarks: :text_area,
     children: :integer_field,
     human: :boolean_field,
     birthdate: :date_field,
     gets_up_at: :time_field,
     companion_id: :belongs_to_field,
     other_ids: :has_many_field,
     more_ids: :has_many_field,
    }.each do |attr, method|
      it "dispatches #{attr} attr to #{method}" do
        form.should_receive(method).with(attr, {})
        form.input_field(attr)
      end

      it { form.input_field(attr).should be_html_safe }
    end

  end

  describe '#labeled_input_fields' do
    subject { form.labeled_input_fields(:name, :remarks, :children) }

    it { should be_html_safe }
    it { should include(form.input_field(:name)) }
    it { should include(form.input_field(:remarks)) }
    it { should include(form.input_field(:children)) }
  end

  describe '#labeled_input_field' do
    context 'when required' do
      subject { form.labeled_input_field(:name) }
      it { should include(StandardFormBuilder::REQUIRED_MARK) }
    end

    context 'when not required' do
      subject { form.labeled_input_field(:remarks) }
      it { should_not include(StandardFormBuilder::REQUIRED_MARK) }
    end

    context 'with help text' do
      subject { form.labeled_input_field(:name, help: 'Some Help') }
      it { should include(form.help_block('Some Help')) }
    end
  end

  describe '#belongs_to_field' do
    it 'has all options by default' do
      f = form.belongs_to_field(:companion_id)
      f.scan('</option>').should have(7).items
    end

    it 'with has options from :list option' do
      list = CrudTestModel.all
      f = form.belongs_to_field(:companion_id, list: [list.first, list.second])
      f.scan('</option>').should have(3).items
    end

    it 'with empty instance list has no select' do
      assign(:companions, [])
      @companions = []
      f = form.belongs_to_field(:companion_id)
      f.should match(/keine verfügbar/m)
      f.scan('</option>').should have(0).items
    end
  end

  describe '#has_and_belongs_to_many_field' do
    let(:others) { OtherCrudTestModel.all[0..1] }

    it 'has all options by default' do
      f = form.has_many_field(:other_ids)
      f.scan('</option>').should have(6).items
    end

    it 'uses options from :list option if given' do
      f = form.has_many_field(:other_ids, list: others)
      f.scan('</option>').should have(2).items
    end

    it 'uses options form instance variable if given' do
      assign(:others, others)
      @others = others
      f = form.has_many_field(:other_ids)
      f.scan('</option>').should have(2).items
    end

    it 'displays a message for an empty list' do
       @others = []
       f = form.has_many_field(:other_ids)
       f.should match /keine verfügbar/m
       f.scan('</option>').should have(0).items
    end
  end

  describe '#string_field' do
    it 'sets maxlength if attr has a limit' do
      form.string_field(:name).should match /maxlength="50"/
    end
  end

  describe '#date_field' do
    it 'sets empty date value' do
      entry.update_column(:birthdate, nil)
      entry.reload
      form.date_field(:birthdate).should_not match /value=/
    end

    it 'sets original date value' do
      entry.update_column(:birthdate, Date.new(2000, 1, 1))
      entry.reload
      form.date_field(:birthdate).should match /value="01.01.2000"/
    end

    it 'sets changed valid date value' do
      entry.birthdate = '1.1.00'
      form.date_field(:birthdate).should match /value="1.1.00"/
    end

    it 'sets changed invalid date value' do
      entry.birthdate = '33.33.33'
      form.date_field(:birthdate).should match /value="33.33.33"/
    end
  end

  describe '#label' do
    context 'only with attr' do
      subject { form.label(:gugus_dada) }

      it { should be_html_safe }
      it 'provides the same interface as rails' do
        should match /label [^>]*for.+Gugus dada/
      end
    end

    context 'with attr and text' do
      subject { form.label(:gugus_dada, 'hoho') }

      it { should be_html_safe }
      it 'provides the same interface as rails' do
        should match /label [^>]*for.+hoho/
      end
    end

  end

  describe '#labeled' do
    context 'in labeled_ method' do
      subject { form.labeled_string_field(:name) }

      it { should be_html_safe }
      it 'provides the same interface as rails' do
        should match /label [^>]*for.+input/m
      end
    end

    context 'with custom content in argument' do
      subject { form.labeled('gugus', "<input type='text' name='gugus' />".html_safe) }

      it { should be_html_safe }
      it { should match /label [^>]*for.+<input/m }
    end

    context 'with custom content in block' do
      subject { form.labeled('gugus') { "<input type='text' name='gugus' />".html_safe } }

      it { should be_html_safe }
      it { should match /label [^>]*for.+<input/m }
    end

    context 'with caption and content in argument' do
      subject { form.labeled('gugus', 'Caption', "<input type='text' name='gugus' />".html_safe) }

      it { should be_html_safe }
      it { should match /label [^>]*for.+>Caption<\/label>.*<input/m }
    end

    context 'with caption and content in block' do
      subject { form.labeled('gugus', 'Caption') { "<input type='text' name='gugus' />".html_safe } }

      it { should be_html_safe }
      it { should match /label [^>]*for.+>Caption<\/label>.*<input/m }
    end
  end

  describe '#required_mark' do
    it 'is shown for required attrs' do
      form.required_mark(:name).should == StandardFormBuilder::REQUIRED_MARK
    end

    it 'is not shown for optional attrs' do
      form.required_mark(:rating).should be_empty
    end

    it 'is not shown for non existing attrs' do
      form.required_mark(:not_existing).should be_empty
    end
  end

  it 'handles missing methods' do
    expect { form.blabla }.to raise_error(NoMethodError)
  end

  context '#respond_to?' do
    it 'returns false for non existing methods' do
      form.respond_to?(:blabla).should be_false
    end

    it 'returns true for existing methods' do
      form.respond_to?(:text_field).should be_true
    end

    it 'returns true for labeled_ methods' do
      form.respond_to?(:labeled_text_field).should be_true
    end
  end
end
