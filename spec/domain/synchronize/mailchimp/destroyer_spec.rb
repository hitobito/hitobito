require 'spec_helper'
require 'digest/md5'

describe Synchronize::Mailchimp::Destroyer do
  let(:user)  { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }

  subject { Synchronize::Mailchimp::Destroyer.new(mailing_list.mailchimp_list_id,
                                                  mailing_list.mailchimp_api_key,
                                                  mailing_list.people) }

  before :each do
    stub_request(:post, "https://us12.api.mailchimp.com/3.0/batches").
      with(headers: {
      'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Authorization'=>'Basic YXBpa2V5OjEyMzQ1Njc4OTBkNjZkMjVjYzVjOTI4NWFiNWE1NTUyLXVzMTI=',
      'Content-Type'=>'application/json',
      'User-Agent'=>'Faraday v0.15.2'
    }).
    to_return(status: 200, body: "", headers: {})
  end

  it "prepares deleting operations." do
    expect(subject.send(:deleting_operations)).to eq [{ method: "DELETE",
                                                        path: "lists/#{mailing_list.mailchimp_list_id}/members/#{Digest::MD5.hexdigest(mailing_list.people[0].email)}"}
    ]
  end
end
