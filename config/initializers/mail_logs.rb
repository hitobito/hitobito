ActiveSupport::Notifications.subscribe "deliver.action_mailer" do |name, started, finished, unique_id, data|   
    fields = %i[mailer subject from to cc bcc message_id date]
    description = data.slice(*fields).map {|k, v| "#{k}: #{v.inspect}"}.join(', ')
    Rails.logger.info "Mail sent. #{description}"
end