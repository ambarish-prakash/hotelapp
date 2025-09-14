# frozen_string_literal: true
module Procurement
  module Transformers
    class UnknownTransformer < StandardError; end

    MAP = {
      acme:       "Procurement::Transformers::AcmeTransformer",
      patagonia:  "Procurement::Transformers::PatagoniaTransformer",
      paperflies: "Procurement::Transformers::PaperfliesTransformer",
    }.freeze

    # Keep the same API you were calling before
    def self.for(source)
      klass_name = MAP[source.to_sym]
      raise UnknownTransformer, "No transformer for #{source.inspect}" unless klass_name
      klass_name.constantize
    end
  end
end

