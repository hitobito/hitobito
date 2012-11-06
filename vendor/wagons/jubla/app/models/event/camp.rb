class Event::Camp < Event

  attr_accessible :number

  # This statement is required because this class would not be loaded otherwise.
  load Rails.root.join(*%w(vendor wagons jubla app models event camp role coach.rb))

  include Jubla::Event::Camp::AffiliateCoach

end
