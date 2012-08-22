ENV['APP_ROOT'] ||= File.expand_path(__FILE__).split("vendor#{File::SEPARATOR}wagons").first

source "http://rubygems.org"

# Declare your gem's dependencies in jubla_jubla.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Load application Gemfile for all application dependencies.
eval File.read(File.expand_path('Gemfile', ENV['APP_ROOT']))

group :development, :test do
  # Explicitly define the path for dependencies on other wagons.
  # gem 'jubla_other_wagon', :path => "#{ENV['APP_ROOT']}/vendor/wagons"
end
