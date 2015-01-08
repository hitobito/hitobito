# encoding: utf-8

#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe I18nEnums do

  let(:person) { Person.new(first_name: 'Dummy') }

  it 'returns translated labels' do
    person.gender = 'm'
    person.gender_label.should eq 'männlich'
    person.gender = 'w'
    person.gender_label.should eq 'weiblich'
    person.gender = nil
    person.gender_label.should eq 'unbekannt'
  end

  it 'returns translated label in french' do
    I18n.locale = :fr
    person.gender = 'm'
    person.gender_label.should eq 'Masculin'
    person.gender = 'w'
    person.gender_label.should eq 'Féminin'
    person.gender = ''
    person.gender_label.should eq 'Inconnu'
    I18n.locale = :de
  end

  it 'accepts only possible values' do
    person.gender = 'm'
    person.should be_valid
    person.gender = ' '
    person.should be_valid
    person.gender = nil
    person.should be_valid
    person.gender = 'foo'
    person.should_not be_valid
  end

  it 'has class side method to return all labels' do
    Person.gender_labels.should eq({ m: 'männlich', w: 'weiblich' })
  end
end
