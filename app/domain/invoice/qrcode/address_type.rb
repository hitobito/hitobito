class Invoice::Qrcode::AddressType < ActiveRecord::Type::Value
  # to db
  def serialize(result)
    result ? result.to_h.to_json : nil
  end

  # from user or db
  def cast(value)
    case value
    when String then Invoice::Qrcode::Address.new(**JSON.parse(value).symbolize_keys)
    when Hash then Invoice::Qrcode::Address.new(**value)
    else value
    end
  end
end
