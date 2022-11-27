class PersonResource < Graphiti::Resource
  self.adapter = Graphiti::Adapters::ActiveRecord
  attribute :first_name, :string
end
