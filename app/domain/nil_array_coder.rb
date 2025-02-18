# frozen_string_literal: true

class NilArrayCoder
  def self.dump(object)
    object.to_json # Convert Ruby array to JSON string
  end

  def self.load(data)
    return [] if data.nil? # Handle NULL values from the database
    begin
      JSON.parse(data)
    rescue
      []
    end # Convert JSON string to array; rescue invalid data
  end
end
