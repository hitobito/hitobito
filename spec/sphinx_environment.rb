require 'thinking_sphinx/test'

def sphinx_environment(*tables, &block)
  obj = self
  transactional = self.use_transactional_fixtures
  begin
    before(:all) do
      obj.use_transactional_fixtures = false
      DatabaseCleaner.strategy = :truncation, {:only => tables}
      ThinkingSphinx::Test.init
    end
    
    before(:each) do
      ThinkingSphinx::Test.index
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
      DatabaseCleaner.strategy = defined?(DB_CLEANER_STRATEGY) ? DB_CLEANER_STRATEGY : :transaction
      obj.use_transactional_fixtures = transactional
    end
  end
end