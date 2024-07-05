# frozen_string_literal: true

class MailConfig
  MAIL_CONFIG_PATH = Rails.root.join("config", "mail.yml")

  class << self
    def legacy?
      config_file.blank?
    end

    def retriever_imap?
      config_file.present? &&
        retriever_imap[:address].present?
    end

    def retriever_imap
      @retriever_imap ||= retriever_imap_config
    end

    private

    def retriever_imap_config
      config = config_file[:imap]
      decode_password(config)
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
      return nil unless File.exist?(MAIL_CONFIG_PATH)

      YAML.safe_load_file(MAIL_CONFIG_PATH).try(:deep_symbolize_keys)
    end
  end
end
