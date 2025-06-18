require 'rails_helper'

describe Dropdown::PeopleFilter do
  let(:template) { ApplicationController.helpers }
  let(:person) { people(:top_leader) }

  before do
    allow(template).to receive(:group_people_filter_criterion_path) do |args|
      "/fake_path_for_#{args[:criterion]}"
    end
  end

  describe '#to_s' do
    it 'renders the dropdown with criteria items' do
      dropdown = described_class.new(template, person, ["role", "tag"])
      output = dropdown.to_s

      expect(output).to include('dropdown-option-qualification')
      expect(output).to include('dropdown-option-attributes')
      expect(output).to include('filter-criteria-dropdown') # ID from the component
    end

    it 'hides dropdown when all criteria are active' do
      dropdown = described_class.new(template, person, ["role", "tag", "qualification", "attributes"])
      expect(dropdown.to_s).to be_nil
    end
  end
end
