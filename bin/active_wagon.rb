#!/usr/bin/env ruby
require 'fileutils'
require 'pathname'

## Allows switching wagons quickly (depends on https://direnv.net/)

class Setup

  def run
    write_and_copy('.envrc', environment)

    if `git rev-parse --abbrev-ref HEAD`.strip == 'rails-5'
      write_and_copy('.tool-versions', 'ruby 2.5.5')
    else
      write_and_copy('.tool-versions', 'ruby 2.2.7')
    end

    write('Wagonfile', gemfile)
    FileUtils.rm_rf(root.join('tmp'))
  end

  def write(name, content)
    File.write(root.join(name), strip_heredoc(content))
  end

  def write_and_copy(name, content)
    write(name, content)
    FileUtils.cp(root.join(name), root.join("../hitobito_#{wagon}"))
  end

  def wagon(name = ARGV.first)
    if !available.include?(name)
      puts "Specify one of the following: #{available.join('|')}"
      exit
    end
    name
  end

  def gemfile
    <<-EOF
    # vim:ft=ruby

    group :development do
      ENV.fetch('WAGONS').split.each do |wagon|
        Dir[File.expand_path("../../hitobito_\#{wagon}/hitobito_\#{wagon}.gemspec", __FILE__)].each do |spec|
          gem File.basename(spec, '.gemspec'), :path => File.expand_path('..', spec)
        end
      end
    end
    EOF
  end

  def environment
    <<-EOF
    PATH_add bin
    export RAILS_DB_ADAPTER=mysql2
    export RAILS_DB_NAME=hit_#{wagon}_development
    export RAILS_TEST_DB_NAME=hit_#{wagon}_test
    export RAILS_PRODUCTION_DB_NAME=hit_#{wagon}_production
    export RUBYOPT=-W0
    export WAGONS="#{wagons.join(' ')}"
    log_status "hitobito now uses: #{wagons.join(', ')}"
    source_up
    EOF
  end

  def root
    @root ||= Pathname.new(File.expand_path('../../', __FILE__))
  end

  def wagons
    [wagon] + dependencies.fetch(wagon, [])
  end

  def dependencies
    %w(pbs cevi pro_natura).product([%w(youth)]).to_h.merge('jubla' => %w(youth jubla_ci))
  end

  def available(excluded = %w(youth jubla_ci site tenants))
    @available ||= root.parent.entries
      .collect { |x| x.to_s[/hitobito_(.*)/, 1]  }
      .compact.reject(&:empty?) - excluded
  end

  def strip_heredoc(string)
    val = string.scan(/^[ \t]*(?=\S)/).min
    indent = val ? val.size : 0
    string.gsub(/^[ \t]{#{indent}}/, '')
  end

end

Setup.new.run
