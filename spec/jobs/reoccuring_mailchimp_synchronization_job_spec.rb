# encoding: utf-8

#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe ReoccuringMailchimpSynchronizationJob do
  let(:group) { groups(:top_group) }

  def create(state = nil)
    Fabricate(:mailing_list, group: group, mailchimp_list_id: 1, mailchimp_api_key: 1).tap do |list|
      data = case state
             when :failed then  { exception: ArgumentError.new('ouch') }
             when :success then { foo: { total: 1, success: 1 } }
             when :partial then { foo: { failed: 1 }, bar: { success: 1 } }
             when :unchanged then {}
             end
      list.update!(mailchimp_result: Synchronize::Mailchimp::Result.new(data)) if data
    end
  end

  subject { ReoccuringMailchimpSynchronizationJob.new }

  it 'ignores list not linked' do
    Fabricate(:mailing_list, group: group)
    expect { subject.perform }.not_to change { Delayed::Job.count }
  end

  it 'ignores list with failed result' do
    create(:failed)
    expect { subject.perform }.not_to change { Delayed::Job.count }
  end

  %i[success partial unchanged].each do |state|
    it "enqueues job for #{state}" do
      create(state)
      expect { subject.perform }.to change { Delayed::Job.count }.by(1)
    end
  end

end
