module JsonHelper

  def api_response(json, object, key = nil)
    json.set! key || model_class.model_name.plural do
      json.array!(Array(object)) do |entry|
        json.id entry.id

        yield entry
      end
    end
  end

  def json_extensions(json, key, options = {})
    find_extension_partials(key, options.delete(:folder)).each do |partial|
      json.partial! options.merge(:partial => partial)
    end
  end

  def json_contact_accounts(json, accounts, only_public)
    json.set! accounts.klass.model_name.plural do
      json.array! accounts.select { |a| a.public? || !only_public } do |account|
        json.extract!(account, :id,
                              account.value_attr,
                              :label,
                              :public)
        yield account if block_given?
      end
    end
  end
end
