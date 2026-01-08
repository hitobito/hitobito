# frozen_string_literal: true

#  Copyright (c) 2025, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "net/sftp"

class Sftp
  Error = Class.new(StandardError)
  ConnectionError = Class.new(StandardError)
  Config = Struct.new(*ConfigContract.keys, keyword_init: true)

  def initialize(config)
    result = ConfigContract.new.call(config.to_h)
    raise ArgumentError, format_config_errors(result) if result.failure?

    @config = Config.new(**result.to_h)
  end

  def upload_file(data, file_path)
    file_path = Pathname.new(file_path)
    create_missing_directories(file_path) if create_directories?

    Tempfile.open("hitobito-sftp-upload", binmode: true) do |tempfile|
      tempfile.write(data)
      tempfile.close
      connection.upload!(tempfile.path, file_path)
    end
  rescue => e
    raise Error, "Failed to upload file to #{file_path}: #{e.message}"
  end

  def create_remote_dir(dir_path)
    connection.mkdir!(dir_path)
  rescue => e
    raise Error, "Failed to create remote directory #{dir_path}: #{e.message}"
  end

  def directory?(dir_path)
    connection.file.directory?(dir_path)
  rescue
    false
  end

  private

  def server_version
    connection.session.transport.server_version.version || "unknown"
  end

  # On AWS SFTP, directories are created automatically. On other servers,
  # we need to create them manually.
  def create_directories?
    !/AWS_SFTP/.match?(server_version)
  end

  def create_missing_directories(file_path)
    file_path.dirname.descend do |directory_path|
      create_remote_dir(directory_path) unless directory?(directory_path)
    end
  end

  def connection
    @connection ||= Net::SFTP.start(@config.host, @config.user, options).tap(&:connect!)
  rescue => e
    raise ConnectionError, e.message
  end

  def options
    credentials = if @config.private_key.present?
      {key_data: [@config.private_key]}
    else
      {password: @config.password}
    end
    credentials.merge(non_interactive: true, port: @config.port).compact
  end

  def format_config_errors(result)
    "Invalid SFTP configuration: #{result.errors(full: true).to_h.values.join(", ")}"
  end
end
