# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe MailingListDecorator  do
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:decorator)    { MailingListDecorator.new(mailing_list) }


  describe "#subscribable_info" do
    subject { decorator.subscribable_info }

    context "subscribable true" do
      it { is_expected.to match(%r{Abonnenten dürfen sich selbst an/abmelden}) }
    end

    context "subscribable false" do
      before { mailing_list.update_column(:subscribable, false) }
      it { is_expected.to eq "Abonnenten dürfen sich <strong>nicht</strong> selbst an/abmelden<br />" }
    end
  end


  describe "#subscribers_may_post_info" do
    subject { decorator.subscribers_may_post_info }

    context "subscribers_may_post true" do
      before { mailing_list.update_column(:subscribers_may_post, true) }
      it { is_expected.to eq "Abonnenten dürfen auf die Mailingliste schreiben<br />" }
    end

    context "subscribers_may_post false" do
      it { is_expected.to eq "Abonnenten dürfen <strong>nicht</strong> auf die Mailingliste schreiben<br />" }
    end
  end

  describe "#anyone_may_post_info" do
    subject { decorator.anyone_may_post_info }

    context "anyone_may_post true" do
      before { mailing_list.update_column(:anyone_may_post, true) }
      it { is_expected.to eq "Beliebige Absender/-innen dürfen auf die Mailingliste schreiben<br />" }
    end

    context "anyone_may_post false" do
      it { is_expected.to eq "Beliebige Absender/-innen dürfen <strong>nicht</strong> auf die Mailingliste schreiben<br />" }
    end
  end

end
