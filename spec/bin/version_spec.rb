# frozen_string_literal: true

#  Copyright (c) 2023-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

describe 'version' do
  before(:all) do
    if ENV['CI'].present? && system('test $(git tag -l | grep 1.31.0 | wc -l) -eq 0')
      `git tag -f 1.31.0 0e81138bf283778df3d51cb70584ac67cd1c3904`
    end
  end

  context 'version' do
    let(:cmd) { 'version' }

    it 'has a version itself' do
      expect(version(cmd)).to match('2.0.0')
    end

    it 'has a banner' do
      expect(version(cmd)).to match('Show and Suggest version-numbers')
    end
  end

  context 'suggest' do
    let(:cmd) { 'suggest' }

    it 'outputs a suggested version' do
      expect(version(cmd)).to match(/\d+\.\d+\.\d+/)
    end

    it 'can mirror a custom version-number' do
      expect(version("#{cmd} custom XP-NG-NT4")).to eql 'XP-NG-NT4'
    end

    it 'suggests only new minor-versions for regular releases' do
      expect(version("#{cmd} regular")).to match(/\d+\.\d+\.0/)
    end
  end

  context 'current' do
    let(:cmd) { 'current' }

    it 'outputs the current version' do
      expect(version(cmd)).to match(/\d+\.\d+\.\d+/)
    end
  end

  def version(args)
    `version #{args}`.chomp
  end
end
