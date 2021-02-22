#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::ContactAccounts do
  subject { Export::Tabular::People::ContactAccounts }

  context "phone_numbers" do
    it "creates standard key and human translations" do
      expect(subject.key(PhoneNumber, "foo")).to eq :phone_number_foo
      expect(subject.human(PhoneNumber, "foo")).to eq "Telefonnummer foo"
    end
  end

  context "social_accounts" do
    it "creates standard key and human translations" do
      expect(subject.key(SocialAccount, "foo")).to eq :social_account_foo
      expect(subject.human(SocialAccount, "foo")).to eq "Social Media Adresse foo"
    end
  end
end
