# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe IdnSanitizer do

  it 'sanitizes single email' do
    IdnSanitizer.sanitize('foo@exämple.com').should eq('foo@xn--exmple-cua.com')
  end

  it 'sanitizes single email with name' do
    IdnSanitizer.sanitize('Mr. Foo <foo@exämple.com>').should eq('Mr. Foo <foo@xn--exmple-cua.com>')
  end

  it 'keeps regular email' do
    IdnSanitizer.sanitize('foo@example.com').should eq('foo@example.com')
  end

  it 'sanitizes empty email' do
    IdnSanitizer.sanitize(' ').should eq(' ')
  end

  it 'sanitizes regular email with name' do
    IdnSanitizer.sanitize('Mr. Foo <foo@example.com>').should eq('Mr. Foo <foo@example.com>')
  end

  it 'sanitizes multiple emails' do
    IdnSanitizer.sanitize(['foo@exämple.com', 'bar@exämple.com']).should eq(
      ['foo@xn--exmple-cua.com', 'bar@xn--exmple-cua.com'])
  end

end