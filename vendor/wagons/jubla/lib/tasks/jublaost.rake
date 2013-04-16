namespace :jublaost do
  desc "Migrate the db as defined in jubla/lib/jubla_ost/config.yml"
  task :migrate => :environment do
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/config"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/base"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/funktion"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/person_funktion"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/person_schar"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/person"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/region_relei"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/region"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/schar"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/schartyp"

    JublaOst::Base.migrate
  end
end