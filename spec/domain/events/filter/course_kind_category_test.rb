# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Events::Filter::CourseKindCategory do
  let(:person) { people(:top_leader) }
  let(:options) { { kind_used: true } }
  let(:category) { Fabricate(:event_kind_category, label: 'Vorbasiskurse', kinds: [event_kinds(:glk)]) }

  let(:scope) { Events::FilteredList.new(person, {}, options).base_scope }

  subject(:filter) { described_class.new(person, params, options, scope) }

  let(:sql) { filter.to_scope.to_sql }
  let(:where_condition) { sql.sub(/.*(WHERE.*)$/, '\1') }

  context 'generally, it' do
    let(:params) { { category: category.id } }

    it 'produces a scope that checks for course categories' do
      expect(where_condition).to match('event_kind_categories.id = ?')
    end
  end

  context 'without category filter, it' do
    let(:today) { Time.zone.now.to_date.strftime('%F') }
    let(:params) { {} }

    it 'does not mention event_kind_categories' do
      expect(sql).not_to match('event_kind_categories')
    end
  end

  context 'with zero category, it' do
    let(:params) { { category: '0' } }

    it 'produces a scope that checks for NULL course categories' do
      expect(where_condition).to match('event_kind_categories.id IS NULL')
    end
  end

end
