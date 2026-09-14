# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Renders the 207 Multi-Status response of RFC 4918: one entry per resource,
# with the properties a client asked for that we know. Properties we do not
# know are left out rather than reported as 404, which RFC 4918 only asks for
# with a SHOULD and no client depends on.
class Carddav::Multistatus
  STATUS_OK = "HTTP/1.1 200 OK"

  # RFC 6352 allows address-data in the reports only, never in a PROPFIND, and
  # a client asking for all properties would otherwise get every vCard inline.
  ALLPROP_EXCLUDED = [Carddav::Property.carddav("address-data")].freeze

  # +properties+ is either the list of properties a client asked for or :all.
  def initialize(resources, properties)
    @resources = Array(resources)
    @properties = properties
  end

  def to_xml
    Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml["d"].multistatus(namespace_declarations) do
        @resources.each { |resource| response(xml, resource) }
      end
    end.to_xml
  end

  private

  def response(xml, resource)
    xml["d"].response do
      xml["d"].href(resource.href)
      if resource.status
        xml["d"].status(resource.status)
      else
        propstat(xml, resource.properties)
      end
    end
  end

  def propstat(xml, supported)
    found = requested(supported) & supported.keys
    return if found.empty?

    xml["d"].propstat do
      xml["d"].prop do
        found.each { |property| element(xml, property) { supported[property].call(xml) } }
      end
      xml["d"].status(STATUS_OK)
    end
  end

  # The trailing underscore, which nokogiri strips again, keeps property names
  # from colliding with the methods of the builder itself.
  def element(xml, property, &block)
    xml[Carddav::Namespaces::PREFIXES.fetch(property.namespace)]
      .send(:"#{property.name}_", &block)
  end

  def requested(supported)
    (@properties == :all) ? supported.keys - ALLPROP_EXCLUDED : @properties
  end

  def namespace_declarations
    Carddav::Namespaces::PREFIXES.to_h { |namespace, prefix| ["xmlns:#{prefix}", namespace] }
  end
end
