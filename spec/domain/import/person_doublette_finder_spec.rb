# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Import::PersonDoubletteFinder do
  subject { Import::PersonDoubletteFinder.new(attrs) }

  context 'empty attrs' do
    let(:attrs) { {} }
    its(:query) { should eq [''] }
    its(:find_and_update) { should be_nil }
  end

  context 'firstname only' do
    before { Person.create!(attrs)  }
    let(:attrs) { { first_name: 'foo' } }
    its(:query) { should eq ['first_name = ?', 'foo'] }
    its('find_and_update.first_name') { should eq 'foo' }
  end

  context 'email only' do
    before { Person.create!(attrs.merge({ first_name: 'foo' })) }
    let(:attrs) { { email: 'foo@bar.com' } }
    its(:query) { should eq ['email = ?', 'foo@bar.com'] }
    its('find_and_update.first_name') { should eq 'foo' }
  end

  context 'joins with or clause, does not change first_name, adds nickname' do
    before { Person.create!(attrs.merge(first_name: 'foo', nickname: 'foobar')) }
    let(:attrs) { { email: 'foo@bar.com', first_name: 'bla' } }
    its(:query) { should eq ['(first_name = ?) OR email = ?', 'bla', 'foo@bar.com'] }
    its('find_and_update.first_name') { should eq 'bla' }
    its('find_and_update.nickname') { should eq 'foobar' }
  end

  context 'joins others with and' do
    context 'includes valid birthday' do
      before { Person.create!(attrs) }
      let(:attrs) { { last_name: 'bar', first_name: 'foo', zip_code: '213', birthday: '1991-05-06' } }
      its(:query) do should eq ['last_name = ? AND first_name = ? AND zip_code = ? AND birthday = ?',
                                'bar', 'foo', '213', Time.zone.parse('1991-05-06').to_date] end
      its(:find_and_update) { should be_present }
    end

    context 'ignores invalid birthday' do
      before { Person.create!(attrs.merge(birthday: '2000-01-01')) }
      let(:attrs) { { last_name: 'bar', first_name: 'foo', zip_code: '213', birthday: '33.33.33' } }

      its(:query) { should eq ['last_name = ? AND first_name = ? AND zip_code = ?', 'bar', 'foo', '213'] }
      its(:find_and_update) { should be_present }
    end
  end

  context 'multiple updates to the same person' do
    before { Person.create!(attrs.merge({ first_name: 'foo' })) }
    let(:attrs) { { email: 'foo@bar.com' } }
    its('find_and_update.first_name') { should eq 'foo' }
  end

end
