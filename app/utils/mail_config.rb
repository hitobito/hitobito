# frozen_string_literal: true

class MailConfig

  MAIL_CONFIG_PATH = Rails.root.join('config', 'mail.yml')

  class << self

    def legacy?
      config_file.blank?
    end

    def retriever_imap
      @retriever_imap ||= retriever_imap_config
    end

    private

    def retriever_imap_config
      config = config_file[:imap]
      config = decode_password(config)
      config
    end

    def decode_password(config)
      if config[:password].present?
        config[:password] = Base64.decode64(config[:password])
      end
      config
    end

    def config_file
      @config_file ||= load_file.freeze
    end

    def load_file
      YAML.safe_load(File.read(MAIL_CONFIG_PATH)).try(:deep_symbolize_keys)
    end

  end

end
