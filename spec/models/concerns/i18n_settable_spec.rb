# encoding: utf-8

#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe I18nSettable do

  let(:person) { Person.new(first_name: 'Dummy') }

  it 'sets i18n attribute as basic value' do
    person.gender = 'm'
    person.gender.should eq 'm'
    person.gender = 'w'
    person.gender.should eq 'w'
    person.gender = ''
    person.gender.should eq ''
  end

  it 'sets i18n attribute in german' do
    person.gender = 'männlich'
    person.gender.should eq 'm'
    person.gender = 'weiblich'
    person.gender.should eq 'w'
    person.gender = 'unbekannt'
    person.gender.should eq nil
    person.should be_valid
  end

  it 'sets i18n attribute in french' do
    I18n.locale = :fr
    person.gender = 'masculin'
    person.gender.should eq 'm'
    person.gender = 'féminin'
    person.gender.should eq 'w'
    person.gender = 'inconnu'
    person.gender.should eq nil
    person.should be_valid
    I18n.locale = :de
  end

  it 'sets invalid i18n attribute in german' do
    person.gender = 'foo'
    person.gender.should eq 'foo'
    person.should_not be_valid
  end

  it 'sets invalid i18n attribute in french' do
    I18n.locale = :fr
    person.gender = 'weiblich'
    person.gender.should eq 'weiblich'
    person.should_not be_valid
    I18n.locale = :de
  end

  it 'sets i18n boolean attribute in german' do
    person.company = 'JA'
    person.company.should eq true
    person.company = 'Nein'
    person.company.should eq false
  end

  it 'sets i18n boolean attribute in french' do
    I18n.locale = :fr
    person.company = 'ouI'
    person.company.should eq true
    person.company = 'non'
    person.company.should eq false
    I18n.locale = :de
  end

  it 'sets invalid i18n boolean attribute' do
    person.company = 'oui'
    person.company.should eq false
  end

  it 'sets i18n boolean attribute as boolean' do
    person.company = true
    person.company.should eq true
    person.company = false
    person.company.should eq false
  end

  it 'sets i18n boolean attribute as integer' do
    person.company = 1
    person.company.should eq true
    person.company = 0
    person.company.should eq false
  end

  it 'sets i18n boolean attribute as integer string' do
    person.company = '1'
    person.company.should eq true
    person.company = '0'
    person.company.should eq false
  end

  it 'sets i18n boolean attribute as boolean string' do
    person.company = 'true'
    person.company.should eq true
    person.company = 'false'
    person.company.should eq false
  end

  it 'sets i18n boolean attribute as empty string' do
    person.company = ' '
    person.company.should eq false
  end

  it 'sets i18n boolean attribute nil' do
    person.company = nil
    person.company.should eq false
  end

end