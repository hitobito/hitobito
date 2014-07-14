# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe UserSerializer do

  let(:person) do
    p = people(:top_leader)
    p.generate_authentication_token!
    p.decorate
  end

  let(:controller) { double().as_null_object }

  let(:serializer) { UserSerializer.new(person, controller: controller)}
  let(:hash) { serializer.to_hash }

  subject { hash[:people].first }

  it 'contains home url' do
    subject.should have_key(:href)
  end

  it 'contains authentication token' do
    subject.should have_key(:authentication_token)
  end

end