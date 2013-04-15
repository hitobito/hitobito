module JublaOst
  class Funktion < Struct.new(:id)
    Leitung = new(1)
    Lagerleitung = new(5)
    KalaKontakt = new(11)
    Adressverwaltung = new(9)
    Versandadresse = new(7)
    Praeses = new(15)
    Kassier = new(25)
    Material = new(20)
  end
end