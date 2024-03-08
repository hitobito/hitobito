# frozen_string_literal: true

#  Copyright (c) 2024-2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe DocumentationReader do
  subject { described_class.html(filename) }
  let(:filename) { 'development/05_json_api' }

  it 'can generate HTML form a doc-markdown' do
    is_expected.to include('<h2>')
  end

  it 'changes the class-names of tables for styling' do
    is_expected.to include('<table class="table table-striped table-bordered">')
  end

  it 'contains emoji' do
    is_expected.to include('‼️ ')
  end

  it 'has a link to the document on github' do
    is_expected.to match(/<a href='.*#{filename}.md' target='_blank'>Markdown source<\/a>/)
  end
end
