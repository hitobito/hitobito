# frozen_string_literal: true

class MailConfig

  MAIL_CONFIG_PATH = Rails.root.join('config', 'mail.yml')

  class << self

    def legacy?
      config_file.blank?
    end

    def retriever_imap
      config = config_file[:imap]
      config[:password] = Base64.decode64(config[:password])
      config
    end

    private

    def config_file
      @config_file ||= load_file.freeze
    end

    def load_file
      YAML.safe_load(File.read(MAIL_CONFIG_PATH)).try(:deep_symbolize_keys)
    end

  end

end
