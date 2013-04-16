# encoding: utf-8
module JublaOst
  class Funktion < Struct.new(:id, :label)
    cattr_reader :all

    def self.new(id, label)
      instance = super
      @@all ||= {}
      @@all[id] = instance
    end

    Leitung = new(1, 'Leitung')
    Lagerleitung = new(5, 'Lagerleitung')
    KalaKontakt = new(11, 'Kala Kontakt')
    Adressverwaltung = new(9, 'Adressverwaltung')
    Versandadresse = new(7, 'Versandadresse')
    Praeses = new(15, 'Präses')
    Kassier = new(25, 'Kassier')
    Material = new(20, 'Material')


    Mappings = {}
    Mappings[::Group::Flock] = {}
    Mappings[::Group::Flock][nil] = ::Group::Flock::Guide
    Mappings[::Group::Flock][Leitung] = ::Group::Flock::Leader
    Mappings[::Group::Flock][Lagerleitung] = ::Group::Flock::CampLeader
    Mappings[::Group::Flock][Praeses] = ::Group::Flock::President
    Mappings[::Group::Flock][Kassier] = ::Group::Flock::Treasurer
    Mappings[::Group::Flock][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::Flock][Versandadresse] = ::Jubla::Role::DispatchAddress

    Mappings[::Group::RegionalBoard] = {}
    Mappings[::Group::RegionalBoard][nil] = ::Group::RegionalBoard::Member
    Mappings[::Group::RegionalBoard][Leitung] = ::Group::RegionalBoard::Leader
    Mappings[::Group::RegionalBoard][Praeses] = ::Group::RegionalBoard::President
    Mappings[::Group::RegionalBoard][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::RegionalBoard][Versandadresse] = ::Jubla::Role::DispatchAddress

    Mappings[::Group::StateBoard] = {}
    Mappings[::Group::StateBoard][nil] = ::Group::StateBoard::Member
    Mappings[::Group::StateBoard][Leitung] = ::Group::StateBoard::Leader
    Mappings[::Group::StateBoard][Praeses] = ::Group::StateBoard::President
    Mappings[::Group::StateBoard][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::StateBoard][Versandadresse] = ::Jubla::Role::DispatchAddress

    Mappings[::Group::StateProfessionalGroup] = {}
    Mappings[::Group::StateProfessionalGroup][nil] = ::Group::StateProfessionalGroup::Member
    Mappings[::Group::StateProfessionalGroup][Leitung] = ::Group::StateProfessionalGroup::Leader
    Mappings[::Group::StateProfessionalGroup][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::StateProfessionalGroup][Versandadresse] = ::Jubla::Role::DispatchAddress

    Mappings[::Group::StateWorkGroup] = {}
    Mappings[::Group::StateWorkGroup][nil] = ::Group::StateWorkGroup::Member
    Mappings[::Group::StateWorkGroup][Leitung] = ::Group::StateWorkGroup::Leader
    Mappings[::Group::StateWorkGroup][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::StateWorkGroup][Versandadresse] = ::Jubla::Role::DispatchAddress

    Mappings[::Group::RegionalProfessionalGroup] = {}
    Mappings[::Group::RegionalProfessionalGroup][nil] = ::Group::RegionalProfessionalGroup::Member
    Mappings[::Group::RegionalProfessionalGroup][Leitung] = ::Group::RegionalProfessionalGroup::Leader
    Mappings[::Group::RegionalProfessionalGroup][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::RegionalProfessionalGroup][Versandadresse] = ::Jubla::Role::DispatchAddress

    Mappings[::Group::RegionalWorkGroup] = {}
    Mappings[::Group::RegionalWorkGroup][nil] = ::Group::RegionalWorkGroup::Member
    Mappings[::Group::RegionalWorkGroup][Leitung] = ::Group::RegionalWorkGroup::Leader
    Mappings[::Group::RegionalWorkGroup][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::RegionalWorkGroup][Versandadresse] = ::Jubla::Role::DispatchAddress

    Mappings[::Group::SimpleGroup] = {}
    Mappings[::Group::SimpleGroup][nil] = ::Group::SimpleGroup::Member
    Mappings[::Group::SimpleGroup][Leitung] = ::Group::SimpleGroup::Leader
    Mappings[::Group::SimpleGroup][Adressverwaltung] = ::Jubla::Role::GroupAdmin
    Mappings[::Group::SimpleGroup][Versandadresse] = ::Jubla::Role::DispatchAddress
  end
end