%w(base filter abo migrator).each { |file| require_relative "convert_globals_support/#{file}" }

class ConvertGlobalsToSpecificRoles < ActiveRecord::Migration

  def up
    roles.each { |role| Migrator.new(role).perform }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def roles
    [Jubla::Role::GroupAdmin,
     Jubla::Role::DispatchAddress,
     Jubla::Role::Alumnus,
     Jubla::Role::External]
  end
end

