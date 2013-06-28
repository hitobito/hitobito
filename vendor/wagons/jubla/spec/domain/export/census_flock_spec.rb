require 'spec_helper'
describe Export::CensusFlock do

  let(:census_flock) { Export::CensusFlock.new(2012) }
  describe ".headers" do
    subject { Export::CensusFlock }

    its(:labels) { should eq ["Name", "Kontakt Vorname", "Kontakt Nachname", "Adresse", "PLZ", "Ort",
                              "Jubla Versicherung", "Jubla Vollkasko", "Leitende", "Kinder"] }
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
      its(:values) { should eq ["Bern", nil, nil, nil, nil, nil, 'nein', 'nein', 5, 7] }
      
      its(:values) { should have(census_flock.class.labels.size).items }
    end

    describe "address, zip code and town" do
      before { flock.update_attributes(address: 'bar', zip_code: 123, town: 'foo') }
      
      its(:values) { should eq ["Bern", nil, nil, 'bar', 123, 'foo', 'nein', 'nein', 5, 7] }
    end

    describe "contact person" do
      before { flock.update_attribute(:contact_id, people(:top_leader).id) }

      its(:values) { should eq ["Bern", "Top", "Leader", nil, nil, nil, 'nein', 'nein', 5, 7] }
    end

    describe "insurance attributes" do
      before do
        flock.update_attribute(:jubla_insurance, true)
        flock.update_attribute(:jubla_full_coverage, true)
      end

      its(:values) { should eq ["Bern", nil, nil, nil, nil, nil, 'ja', 'ja', 5, 7] }
    end

    describe "without member count" do
      before { MemberCount.where(flock_id: flock.id).destroy_all }
      
      its(:values) { should eq ["Bern", nil, nil, nil, nil, nil, 'nein', 'nein', nil, nil] }
    end
  end

  describe "to_csv" do
    
    subject { Export::Csv::Generator.new(census_flock).csv.split("\n") }

    its(:first) { should eq "Name;Kontakt Vorname;Kontakt Nachname;Adresse;PLZ;Ort;Jubla Versicherung;Jubla Vollkasko;Leitende;Kinder" }
    its(:second) { should eq "Ausserroden;;;;;;nein;nein;;" }
  end
  
end
