# frozen_string_literal: true

#  Copyright (c) 2018-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::ExportBaseJob < BaseJob
  PARAMETERS = [:locale, :format, :exporter, :user_id, :options].freeze

  attr_reader :exporter

  def initialize(format, user_id, options = {})
    super()
    @format = format
    @user_id = user_id
    @options = options
  end

  def perform
    set_locale
    export_file
  end

  def entries
    # override in sub class
  end

  def ability
    @ability ||= Ability.new(user)
  end

  def user
    @user ||= Person.find(@user_id)
  end

  def export_file
    async_download_file.write(data, force_encoding: @options.fetch(:encoding, nil))
  end

  def data
    exporter.export(@format, entries, ability)
  end

  def filename
    @options.fetch(:filename)
  end

  private

  def async_download_file
    @async_download_file ||= AsyncDownloadFile.maybe_from_filename(filename, @user_id, @format)
  end
end
