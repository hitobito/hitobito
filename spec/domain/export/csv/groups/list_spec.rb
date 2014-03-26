require 'spec_helper'

describe Export::Csv::Groups::List do

  let(:group) { groups(:bottom_layer_one) }

  let(:list) { group.self_and_descendants.without_deleted.includes(:contact) }
  let(:data) { Export::Csv::Groups::List.export(list) }
  let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

   its(:headers) do
     should == %w(Id Elterngruppe Name Kurzname Gruppentyp Haupt-E-Mail Adresse PLZ Ort Land Ebene)
   end

   it { should have(4).items }

   context 'first row' do

     subject { csv[0] }

     its(['Id']) { should == group.id.to_s }
     its(['Elterngruppe']) { should == group.parent_id.to_s }
     its(['Name']) { should == group.name }
     its(['Kurzname']) { should == group.short_name }
     its(['Gruppentyp']) { should == 'Bottom Layer' }
     its(['Haupt-E-Mail']) { should == group.email }
     its(['Adresse']) { should == group.address }
     its(['PLZ']) { should == group.zip_code.to_s }
     its(['Ort']) { should == group.town }
     its(['Land']) { should == group.country }
     its(['Ebene']) { should == group.id.to_s }

   end

   context 'group with contact' do

     let(:contact) { people(:bottom_member) }

     subject { csv[1] }

     its(['Elterngruppe']) { should == group.id.to_s }
     its(['Ebene']) { should == group.id.to_s }
     its(['Haupt-E-Mail']) { should == groups(:bottom_group_one_one).email }
     its(['Adresse']) { should == contact.address }
     its(['PLZ']) { should == contact.zip_code.to_s }
     its(['Ort']) { should == contact.town }
     its(['Land']) { should == contact.country }
   end
end
