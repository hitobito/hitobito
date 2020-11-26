# frozen_string_literal: true

#  Copyright (c) 2020, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito_cevi and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cevi.

require 'spec_helper'

describe OrCondition do
  it 'is blank to begin with' do
    expect(subject).to be_blank
  end

  it 'can be extended' do
    expect do
      subject.or('1=1')
      subject.or('foo = ?', 2)
    end.to_not raise_error
  end

  it 'is present if a condition as been added' do
    expect(subject.or('1=1')).to be_present
  end

  it 'can be exported as array' do
    expect(subject.or('foo = ?', 1).to_a).to eq [
      '(foo = ?)', 1
    ]
  end

  it 'wraps clauses in paranthesis' do
    expect(subject.or('foo = ?', 1).to_a.first).to match(/\([^(]*\)/)
  end

  it 'does not contain an OR if only one condition has been added' do
    expect(subject.or('1=1').to_a.first).to_not match(/OR/)
  end

  it 'add ORs to the SQL if multiple conditions are added' do
    expect do
      subject.or('1=1')
      subject.or('foo = ?', 2)

      expect(subject.to_a.first).to match(/OR/)
    end.to_not raise_error
  end

  it 'is exported as useful data for ActiveRecord' do
    subject.or('1=1')
    subject.or('foo = ?', 2)
    subject.or('bar = ? AND baz = ?', 3, 4)

    expect(subject.to_a).to eq [
      '(1=1) OR (foo = ?) OR (bar = ? AND baz = ?)',
      2, 3, 4
    ]
  end

  it 'can add conditions in a chain' do
    subject
      .or('1=1')
      .or('foo = ?', 2)
      .or('bar = ? AND baz = ?', 3, 4)

    expect(subject.to_a).to eq [
      '(1=1) OR (foo = ?) OR (bar = ? AND baz = ?)',
      2, 3, 4
    ]
  end

  it 'allows deletion of clauses' do
    subject.or('1=1')
    subject.or('foo = ?', 2)
    subject.or('bar = ? AND baz = ?', 3, 4)

    subject.delete('foo = ?', 2)

    expect(subject.to_a).to eq [
      '(1=1) OR (bar = ? AND baz = ?)',
      3, 4
    ]
  end
end
