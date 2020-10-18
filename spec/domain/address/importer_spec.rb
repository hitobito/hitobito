# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'
require 'csv'

describe Address::Importer do

  let(:csv) do
    <<~CSV
      00;20200817;13229

      01;1716;351;20;3007;00;3000;Bern;Bern;BE;1;;8837;19860521;301760;J
      04;56035;1716;Belpstrasse;Belpstrasse;Belpstrasse;Belpstrasse;1;1;J;;
      06;7003182;56035;36;;J;N;
      06;7003186;56035;38;;J;N;
      06;7003187;56035;40;;J;N;
      06;8127095;56035;37;;J;N;
      06;8127095;56035;37;;J;N;

      01;1775;356;10;3074;00;3074;Muri b. Bern;Muri b. Bern;BE;1;;7272;19860521;307360;J
      04;57347;1775;Belpstrasse;Belpstrasse;Belpstrasse;Belpstrasse;1;1;J;;
      06;7185168;57347;3;;J;N;

      01;4390;261;20;8005;00;8000;Zürich;Zürich;ZH;1;;9741;19900101;801500;J
      04;64853;4390;Limmatstrasse;Limmatstrasse;Limmatstrasse;Limmatstrasse;1;1;J;;
      06;57006052;64853;214;;J;N;
      06;57006053;64853;215;;J;N;
      06;57006054;64853;217;;J;N;
    CSV
  end

  let(:dir) { Rails.root.join('tmp/post-test') }

  around do |example|
    FileUtils.rm_rf(dir)
    example.run
    FileUtils.rm_rf(dir)
  end

  before do
    allow(subject).to receive(:dir).and_return(dir)
  end

  it 'raises if token is not set' do
    allow(Settings.addresses).to receive(:token).and_return(nil)
    expect { subject.run }.to raise_error(/expected token is blank/)
  end

  it 'fetches and updates addresses' do
    Address.delete_all
    allow(Settings.addresses).to receive(:token).and_return('foo')
    zip = Zip::OutputStream.write_buffer(StringIO.new('sample.zip')) do |out|
      out.put_next_entry('sample.csv')
      out.write csv
    end

    headers = {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Authorization' => 'Basic foo',
      'User-Agent' => 'Faraday v0.15.3'
    }
    stub_request(:get, 'https://webservices.post.ch:17017/IN_ZOPAxFILES/v1/groups/1062/versions/latest/file/gateway').
      with(headers: headers).to_return(status: 200, body: zip.string, headers: {})

    expect do
      subject.run
    end.to change { Address.count }.by(3)

    bs_bern = Address.find_by(street_short: 'Belpstrasse', zip_code: 3007)
    expect(bs_bern.street_long).to eq 'Belpstrasse'
    expect(bs_bern.town).to eq 'Bern'
    expect(bs_bern.zip_code).to eq 3007
    expect(bs_bern.numbers).to eq [36,37,38,40]

    bs_muri = Address.find_by(street_short: 'Belpstrasse', zip_code: 3074)
    expect(bs_muri.street_long).to eq 'Belpstrasse'
    expect(bs_muri.town).to eq 'Muri b. Bern'
    expect(bs_muri.zip_code).to eq 3074
    expect(bs_muri.numbers).to eq [3]
    expect(dir).to be_exist
  end

end
