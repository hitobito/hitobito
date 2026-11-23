# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require Rails.root.join("lib/release/main").to_s

describe Release::Highlevel do
  subject(:releaser) { Release::Main.new([]) }

  let(:branch) { "master" }

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system("git init --quiet --initial-branch=#{branch}", exception: true)
        system("git -c user.name=test -c user.email=test@example.com " \
               "commit --quiet --allow-empty -m init", exception: true)
        FileUtils.mkdir_p(".tx")
        FileUtils.touch(".tx/config")
        example.run
      end
    end
  end

  before do
    allow(releaser).to receive(:puts)
    allow(releaser).to receive(:execute).and_call_original
    allow(releaser).to receive(:execute).with(/\Atx /).and_return(true)
    allow(releaser).to receive(:add)
  end

  context "on the default translations branch" do
    it "pushes translation sources" do
      releaser.send(:upload_translation_sources)

      expect(releaser).to have_received(:execute).with("tx push -s")
    end

    it "pulls translations" do
      releaser.send(:update_translations)

      expect(releaser).to have_received(:execute).with(/\Atx pull/)
    end
  end

  context "on another branch" do
    let(:branch) { "stable" }

    it "does not push translation sources" do
      releaser.send(:upload_translation_sources)

      expect(releaser).not_to have_received(:execute).with(/\Atx /)
    end

    it "does not pull translations" do
      releaser.send(:update_translations)

      expect(releaser).not_to have_received(:execute).with(/\Atx /)
    end
  end

  context "with TRANSLATIONS_BRANCH set to the current branch" do
    let(:branch) { "stable" }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TRANSLATIONS_BRANCH", "master").and_return("stable")
    end

    it "pushes translation sources" do
      releaser.send(:upload_translation_sources)

      expect(releaser).to have_received(:execute).with("tx push -s")
    end
  end
end
