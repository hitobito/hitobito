# frozen_string_literal: true

# Copyright (c) 2022-2022, Digisus Lab. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ProjectAnalyzer do
  it 'has assumptions' do
    expect do
      described_class.new
    end.to raise_error ArgumentError

    expect(described_class.new('foo')).to be_a ProjectAnalyzer
  end

  it 'finds jubla/integration in hit-jubla-int' do
    expect(described_class.new('hit-jubla-int').project).to eq 'jubla'
    expect(described_class.new('hit-jubla-int').stage).to eq 'integration'
  end

  it 'finds pbs/development in hit_pbs_development' do
    expect(described_class.new('hit_pbs_development').project).to eq 'pbs'
    expect(described_class.new('hit_pbs_development').stage).to eq 'development'
  end

  it 'finds hitobito/development in hitobito-development' do
    expect(described_class.new('hitobito-development').project).to eq 'hitobito'
    expect(described_class.new('hitobito-development').stage).to eq 'development'
  end

  it 'finds digisus_lab/production in hit_digisus_lab_prod' do
    expect(described_class.new('hit_digisus_lab_prod').project).to eq 'digisus_lab'
    expect(described_class.new('hit_digisus_lab_prod').stage).to eq 'production'
  end

  it 'finds die-mitte/staging in htbt-die-mitte-staging' do
    expect(described_class.new('htbt-die-mitte-staging').project).to eq 'die-mitte'
    expect(described_class.new('htbt-die-mitte-staging').stage).to eq 'staging'
  end
end
