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
      ThinkingSphinx::Test.run do
        if ThinkingSphinx.sphinx_running?
          DatabaseCleaner.start
          example.call
          DatabaseCleaner.clean
        else
          puts 'SPHINX NOT RUNNING!'
        end
      end
    end

    yield
  ensure
    after(:all) do
      DatabaseCleaner.strategy = :transaction
      obj.use_transactional_fixtures = true
    end
  end
end