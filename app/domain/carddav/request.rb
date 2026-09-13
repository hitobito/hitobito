# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Reads what a client asked for out of the XML body of a PROPFIND or REPORT
# request. A body that is empty or unparseable is treated as a request for all
# properties, as RFC 4918 demands for an empty PROPFIND.
class Carddav::Request
  # Anything else cannot be a valid XML element name and is ignored.
  PROPERTY_NAME = /\A[\w.-]+\z/

  attr_reader :request

  def initialize(request)
    @request = request
  end

  def depth_zero?
    (request.headers["Depth"].presence || "0") == "0"
  end

  # The properties a client asked for, or :all if it asked for all of them.
  def properties
    node = document&.at_xpath("/*/d:prop", "d" => Carddav::Namespaces::DAV)
    return :all if node.nil?

    node.element_children.filter_map { |element| property(element) }.uniq
  end

  # The resources a client asked about, e.g. in an addressbook-multiget.
  def hrefs
    return [] if document.nil?

    document.xpath("/*/d:href", "d" => Carddav::Namespaces::DAV).collect { |node| node.text.strip }
  end

  def report_name
    document&.root&.name
  end

  private

  def property(element)
    return unless element.name.match?(PROPERTY_NAME)

    Carddav::Property.new(element.namespace&.href, element.name)
  end

  def document
    return @document if defined?(@document)

    @document = parse(request.raw_post)
  end

  def parse(body)
    return if body.blank?

    Nokogiri::XML(body, &:nonet)
  rescue Nokogiri::XML::SyntaxError
    nil
  end
end
