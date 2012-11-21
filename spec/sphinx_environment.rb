require 'thinking_sphinx/test'

def sphinx_environment(*tables, &block)
  obj = self
  begin
    before(:all) do
      obj.use_transactional_fixtures = false
      DatabaseCleaner.strategy = :truncation, {:only => tables}
      ThinkingSphinx::Test.init
    end

    around(:each) do |example|
      DatabaseCleaner.start
      ThinkingSphinx::Test.run &example
      DatabaseCleaner.clean
    end

    yield
  ensure
    after(:all) do
      DatabaseCleaner.strategy = :transaction
      obj.use_transactional_fixtures = true
    end
  end
end