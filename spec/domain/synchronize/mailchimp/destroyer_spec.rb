#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "digest/md5"

describe Synchronize::Mailchimp::Destroyer do
  let(:user)  { people(:top_leader) }
  let(:mailing_list) { mailing_lists(:leaders) }

  subject { Synchronize::Mailchimp::Destroyer.new(mailing_list.mailchimp_list_id,
                                                  mailing_list.mailchimp_api_key,
                                                  mailing_list.people) }

  before :each do
    stub_request(:post, "https://us12.api.mailchimp.com/3.0/batches").
      with(headers: {
      "Accept"=>"*/*",
      "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Authorization"=>"Basic YXBpa2V5OjEyMzQ1Njc4OTBkNjZkMjVjYzVjOTI4NWFiNWE1NTUyLXVzMTI=",
      "Content-Type"=>"application/json",
      "User-Agent"=>"Faraday v0.15.3"
    }).
    to_return(status: 200, body: "", headers: {})
  end

  it "prepares deleting operations." do
    mailing_list.subscriptions.create!(subscriber: user)
    expect(subject.send(:deleting_operations)).to eq [{ method: "DELETE",
                                                        path: "lists/#{mailing_list.mailchimp_list_id}/members/#{Digest::MD5.hexdigest(mailing_list.people[0].email)}"}
    ]
  end

  it "prepares no operation if no subscripotion exists" do
    expect(subject.send(:deleting_operations)).to eq []
  end
end
