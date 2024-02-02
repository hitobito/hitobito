
class Payee < ActiveRecord::Base
  belongs_to :payment
  belongs_to :person, optional: true

end
