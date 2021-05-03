require "faker"
class MessageSpike

  def initialize(count = 10, stamped = nil)
    @count = count
    @stamped = stamped
  end

  def run
    render
  end

  def profile
    require 'ruby-prof'
    RubyProf.start
    render
    result = RubyProf.stop
    printer = RubyProf::MultiPrinter.new(result)
    printer.print(:path => Rails.root.join("tmp"), :profile => "profile")
  end

  def render
    exporter = message.exporter_class.new(message, people, stamped: @stamped)
    puts "writing #{filename}"
    puts Benchmark.measure {
      File.open(filename, 'wb') do |f|
        f << exporter.render
      end
    }
  end

  def filename
    parts = [message.id, @count, @stamped ? :stamped : nil].compact.join("_")
    Rails.root.join("tmp/#{parts}.pdf")
  end

  def message
    @message ||= Message.find(150)
  end

  def people
    Person.order(:id).with_address.where.not(email: [nil, '']).limit(@count)
  end
end
