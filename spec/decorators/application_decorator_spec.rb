require 'spec_helper'

describe ApplicationDecorator do
  it "#klass returns model class"  do
    dec = GroupDecorator.new(Group.new)
    dec.klass.should eq Group
  end

  context "userstamp" do
    before do
      @person = Fabricate(:person)
      @creator = Fabricate(:person)
      @updater = Fabricate(:person)
      @person.creator = @creator
      @person.updater = @updater
      @person.save!
    end

    it "should return date and time with updater/creator" do
      dec = PersonDecorator.new(@person)
      dec.stub(:can?).and_return(true)
      dec.created_info.should =~ /#{I18n.l(@person.created_at.to_date)}/
      dec.created_info.should =~ /#{@creator.to_s}/
      dec.updated_info.should =~ /#{I18n.l(@person.updated_at.to_date)}/
      dec.updated_info.should =~ /#{@updater.to_s}/
    end
  end


end
