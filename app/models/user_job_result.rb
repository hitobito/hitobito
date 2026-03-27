# frozen_string_literal: true

#  Copyright (c) 2012-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: async_download_files
#
#  id         :bigint           not null, primary key
#  filetype   :string
#  name       :string           not null
#  progress   :integer
#  timestamp  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  person_id  :integer          not null
#

class UserJobResult < ApplicationRecord
  belongs_to :delayed_job, class_name: "Delayed::Backend::ActiveRecord::Job", optional: true

  has_one_attached :generated_file

  after_create_commit -> { broadcast_prepend_to "user_job_results" }
  after_update_commit -> { broadcast_replace_to "user_job_results" }
  after_destroy_commit -> { broadcast_remove_to "user_job_results" }

  before_destroy do
    generated_file.purge if generated_file.attached?
  end

  def to_s
    partial = " (#{progress}%)" if progress.present?

    "<AsyncDownloadFile##{id}: #{filename}#{partial}>"
  end

  def downloadable?(person)
    (person_id == person.id) && generated_file.attached?
  end

  def write(data, force_encoding: nil)
    io = StringIO.new

    case filetype.to_sym
    when :csv then io.set_encoding(Settings.csv.encoding)
    when :pdf then io.binmode
    end

    io.set_encoding(force_encoding) if force_encoding.present?

    io.write(data)
    io.rewind # make ActiveStorage's checksum-calculation deterministic

    generated_file.attach(io: io, filename:)
  end

  def read
    data = generated_file.download
    if filetype.to_sym == :csv && data.present?
      data = data.force_encoding(Settings.csv.encoding)
    end
    data
  end
end
