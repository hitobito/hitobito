require 'spork'

Spork.prefork do
  require_relative 'spec_helper_base.rb'
end

Spork.each_run do
  load File.expand_path("../shared_db_connection.rb", __FILE__)
end
