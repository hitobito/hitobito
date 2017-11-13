# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'zip'

class Export::ExportBaseJob < BaseJob

  PARAMETERS = [:format, :exporter, :user_id, :tempfile_name].freeze

  attr_reader :exporter

  def perform
    set_locale
    file, format = export_file_and_format
    send_mail(recipient, file, format)
  ensure
    if file != export_file
      file.close
      file.unlink
    end
    export_file.close
    export_file.unlink
  end

  def send_mail
    # override in sub class
  end

  def entries
    # override in sub class
  end

  def recipient
    @recipient ||= Person.find(@user_id)
  end

  def export_file_and_format
    return [export_file, @format] if export_file.size < 512.kilobyte

    # size reduction is by 70-80 %
    zip = Tempfile.new("#{@tempfile_name}-zip", encoding: 'ascii-8bit')
    Zip::OutputStream.open(zip.path) do |zos|
      zos.put_next_entry "entry.#{@format}"
      zos.write export_file.read
    end

    [zip, :zip]
  end

  def export_file
    @export_file ||= begin
                       file = Tempfile.new("#{@tempfile}-export")
                       file << data
                       file.rewind # make subsequent read-calls start at the beginning
                       file
                     end
  end

  def data
    exporter.export(@format, entries)
  end

end
