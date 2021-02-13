require "spec_helper"

describe Person::Filter::Chain do
  context "initialize" do
    it "only build present filters" do
      chain = Person::Filter::Chain.new(role: {role_type_ids: ""}, qualification: {})
      expect(chain).to be_blank
    end

    it "ignores unknown filters" do
      chain = Person::Filter::Chain.new(ratatui: {query: "foo"}, qualification: {qualification_kind_ids: "20"})
      expect(chain).to be_present
      expect(chain.filters.size).to eq(1)
    end
  end

  context "to_params" do
    it "includes all present filters" do
      chain = Person::Filter::Chain.new(role: {role_type_ids: "2-6-9"},
                                        qualification: {qualification_kind_ids: []})
      expect(chain.to_params).to eq({role: {role_type_ids: "2-6-9"}})
    end
  end

  context "dump" do
    it "serializes all present filters" do
      chain = Person::Filter::Chain.new(role: {role_type_ids: "2-6-9"},
                                        qualification: {qualification_kind_ids: ["14"]})
      yaml = Person::Filter::Chain.dump(chain)
      roundtrip = Person::Filter::Chain.load(yaml)
      expect(roundtrip.to_params.deep_stringify_keys).to eq(
        {role: {role_type_ids: "2-6-9"},
         qualification: {qualification_kind_ids: "14"}}.deep_stringify_keys
      )
    end
  end
end
