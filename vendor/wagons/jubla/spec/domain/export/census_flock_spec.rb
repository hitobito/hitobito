require 'spec_helper'
describe Export::CensusFlock do

  let(:census_flock) { Export::CensusFlock.new(2012) }
  describe ".headers" do
    subject { Export::CensusFlock }

    its(:labels) { should eq ["Name", "Kontakt Vorname", "Kontakt Nachname", "Adresse", "PLZ", "Ort",
                              "Jubla Versicherung", "Jubla Vollkasko", "Leiter", "Kinder"] }
  end

  describe "census flock" do
    
    subject { census_flock }

    it { should have(5).items }

    it "orders by groups.lft and name" do
      subject.items[0][:name].should eq 'Ausserroden'
      subject.items[1][:name].should eq 'Bern'
    end
  end

  describe "mapped items" do
    let(:flock) { groups(:bern) }

    subject { census_flock.items[1] }

    describe "keys and values" do

      its(:keys) { should eq [:name, :contact_first_name, :contact_last_name, :address, :zip_code, :town,
                              :jubla_insurance, :jubla_full_coverage, :leader_count, :child_count]  }
      its(:values) { should eq ["Bern", nil, nil, nil, nil, nil, false, false, 5, 7] }
    end

    describe "address, zip code and town" do
      before { flock.update_attributes(address: 'bar', zip_code: 123, town: 'foo') }
      
      its(:values) { should eq ["Bern", nil, nil, 'bar', 123, 'foo', false, false, 5, 7] }
    end

    describe "contact person" do
      before { flock.update_attribute(:contact_id, people(:top_leader).id) }

      its(:values) { should eq ["Bern", "Top", "Leader", nil, nil, nil, false, false, 5, 7] }
    end

    describe "insurance attributes" do
      before do
        flock.update_attribute(:jubla_insurance, true)
        flock.update_attribute(:jubla_full_coverage, true)
      end

      its(:values) { should eq ["Bern", nil, nil, nil, nil, nil, true, true, 5, 7] }
    end

    describe "without member count" do
      before { MemberCount.where(flock_id: flock.id).destroy_all }
      
      its(:values) { should eq ["Bern", nil, nil, nil, nil, nil, false, false, nil, nil] }
    end
  end

  describe "to_csv" do
    
    subject { census_flock.to_csv.split("\n") }

    its(:first) { should eq "Name;Kontakt Vorname;Kontakt Nachname;Adresse;PLZ;Ort;Jubla Versicherung;Jubla Vollkasko;Leiter;Kinder" }
    its(:second) { should eq "Ausserroden;;;;;;false;false;;" }
  end
  
end
