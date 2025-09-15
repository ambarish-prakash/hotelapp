# frozen_string_literal: true

module Procurement
  module Importers
    class UnknownImporter < StandardError; end

    MAP = {
      acme:       "Acme::HotelImporter",
      patagonia:  "Patagonia::HotelImporter",
      paperflies: "Paperflies::HotelImporter"
    }.freeze

    def self.for(source)
      klass_name = MAP[source.to_sym]
      raise UnknownImporter, "No importer for #{source.inspect}" unless klass_name
      klass_name.constantize
    end
  end
end
