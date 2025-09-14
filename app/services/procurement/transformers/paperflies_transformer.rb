# frozen_string_literal: true
module Procurement
  module Transformers
    class PaperfliesTransformer
      # raw: parsed JSON from Fetcher (Hash or Array)
      # Return: Array of normalized attribute Hashes for your model
      def self.transform(raw)
        return raw
      end
    end
  end
end
