# encoding: UTF-8
require "spec_helper"

describe CensusMailer do

  before do
    SeedFu.quiet = true
    SeedFu.seed [JublaJubla::Wagon.root.join('db', 'seeds')]
  end

  let(:person) { people(:top_leader) }
  let(:census) { censuses(:two_o_12) }

  subject { mail }

  describe "#invitation" do
    let(:mail) { CensusMailer.invitation(census, ['test@example.com', 'test2@example.com']) }

    its(:subject) { should == "Bestandesmeldung ausfüllen" }
    its(:to)      { should == ['noreply@localhost'] }
    its(:bcc)     { should == ['test@example.com', 'test2@example.com'] }
    its(:from)    { should == ["noreply@localhost"] }
    its(:body)    { should =~ /bis am 31\.10\.2012/ }
  end


  describe "#reminder" do
    let(:leaders) do
      [Fabricate.build(:person, email: 'test@example.com', first_name: 'firsty'),
       Fabricate.build(:person, email: 'test2@example.com', first_name: 'lasty')]
    end

    context "with contact address" do
      let(:mail) { CensusMailer.reminder(people(:top_leader).email, census, leaders, groups(:bern), groups(:be_agency)) }

      its(:subject) { should == "Bestandesmeldung ausfüllen!" }
      its(:to)      { should == ['test@example.com', 'test2@example.com'] }
      its(:from)    { should == [people(:top_leader).email] }
      its(:body)    { should =~ /Hallo firsty, lasty/ }
      its(:body)    { should =~ /AST<br\/>3000 Bern<br\/>ast_be@jubla.example.com/ }
      its(:body)    { should =~ /bis am 31\.10\.2012/ }
    end

    context "without contact address" do
      let(:mail) { CensusMailer.reminder(people(:top_leader).email, census, leaders, groups(:bern), groups(:no_agency)) }

      its(:body) { should =~ /AST<br\/><br\/>/ }
    end
  end
end