#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ApplicationDecorator do
  it "#klass returns model class" do
    dec = GroupDecorator.new(Group.new)
    expect(dec.klass).to eq Group
  end

  context "userstamp" do
    before do
      Person.reset_stamper
      @person = Fabricate(:person)
      @creator = Fabricate(:person)
      @updater = Fabricate(:person)
      @person.creator = @creator
      @person.updater = @updater
      @person.save!
    end

    it "should return date and time with updater/creator" do
      dec = PersonDecorator.new(@person)
      expect(@person.creator).to eq(@creator)
      expect(@person.updater).to eq(@updater)
      allow(dec).to receive(:can?).and_return(true)
      begin
        expect(dec.created_info).to match(/#{I18n.l(@person.created_at.to_date)}/)
        expect(dec.created_info).to match(/#{@creator}/)
        expect(dec.updated_info).to match(/#{I18n.l(@person.updated_at.to_date)}/)
        expect(dec.updated_info).to match(/#{@updater}/)
      rescue ActionController::RoutingError => e
        # this weird bitch pops up on rare occasions - let's figure out why
        puts e.message
        puts e.backtrace.join("\n\t")
        puts "Person:"
        p @person
        puts "Creator:"
        p @creator
        puts "Updater:"
        p @updater
        puts "Other person ids:"
        p Person.pluck(:id)
      end
    end
  end
end
