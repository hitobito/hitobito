namespace :jublaost do
  desc "Migrate the db as defined in jubla/lib/jubla_ost/config.yml"
  task :migrate => :environment do
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/config"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/base"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/funktion"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/kurs"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/kurs_basisgruppe"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/kurs_tn_status"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/person_funktion"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/person_kurs"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/person_schar"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/person"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/region_relei"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/region"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/schar"
    require "#{JublaJubla::Wagon.root}/lib/jubla_ost/schartyp"

    start = Time.now
    old_count = counts

    JublaOst::Base.migrate

    seconds = (Time.now - start).to_i
    minutes = seconds / 60

    puts "\n\nMigrated the following models in #{minutes}:#{seconds % 60} minutes"
    counts.each do |model, count|
      puts "#{count - old_count[model]} #{model.model_name.pluralize}"
    end
  end
end

def counts
  [Group,
   Event,
   Person,
   Role,
   Qualification,
   Event::Participation,
   Event::Date,
   Event::Question,
   Event::Answer,
   PhoneNumber,
   SocialAccount
  ].each_with_object({}) do |model, all|
    all[model] = model.count
  end
end
