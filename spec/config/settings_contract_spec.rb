# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs

require "spec_helper"

describe SettingsContract do
  let(:settings) do
    {
      people: {
        inactivity_block: {
          warn_after: "P1Y",
          block_after: "P1Y"
        },
        cleanup_cutoff_duration: {
          regarding_current_sign_in_at: "P1Y",
          regarding_roles: "P1Y",
          regarding_event_participations: "P1Y"
        }
      },
      event: {
        participations: {
          delete_additional_information_after_months: "P1Y"
        }
      }
    }
  end

  subject { described_class.new.call(settings) }

  context "with valid settings" do
    it { is_expected.to be_success }
  end

  it "accepts nil values" do
    set_settings(nil)

    is_expected.to be_success
  end

  context "with invalid data types" do
    before { set_settings(12345) }

    it { is_expected.not_to be_success }

    it "has the correct error message" do
      subject.errors.all? do |error|
        expect(error.to_s).to include("must be a string")
      end
    end
  end

  context "with invalid format" do
    before { set_settings("12345") }

    it { is_expected.not_to be_success }

    it "has the correct error message" do
      subject.errors.all? do |error|
        expect(error.to_s).to include("must be a valid ISO8601 duration string")
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  def set_settings_to(value)
    settings[:people][:inactivity_block][:warn_after] = value
    settings[:people][:inactivity_block][:block_after] = value
    settings[:people][:cleanup_cutoff_duration][:regarding_current_sign_in_at] = value
    settings[:people][:cleanup_cutoff_duration][:regarding_roles] = value
    settings[:people][:cleanup_cutoff_duration][:regarding_event_participations] = value
    settings[:event][:participations][:delete_additional_information_after_months] = value
  end
  # rubocop:enable Metrics/AbcSize
end
