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

def index_sphinx
  ThinkingSphinx::Test.index
  # Wait for index to finish. If entries are not found, probably increase the sleep period.
  sleep 1
  sleep 0.25 until index_finished?
end

def index_finished?
  Dir[Rails.root.join('db', 'sphinx', 'test', '*.{new,tmp}.*')].empty?
end