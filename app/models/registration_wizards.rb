module RegistrationWizards
  def self.for(_group, person = nil)
    person.present? ? ::Wizards::InscribeInGroupWizard : Wizards::RegisterNewUserWizard
  end
end
