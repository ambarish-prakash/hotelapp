# frozen_string_literal: true
require "net/http"
require "json"

module Procurement
  class Fetcher
    class Error < StandardError; end

    def self.call(url, headers: {})
      uri = URI(url)
      res = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5, read_timeout: 15, write_timeout: 5
      ) do |http|
        req = Net::HTTP::Get.new(uri)
        headers.each { |k, v| req[k] = v }
        http.request(req)
      end

      unless res.is_a?(Net::HTTPSuccess)
        raise Error, "HTTP #{res.code} from #{url}: #{res.body&.slice(0,500)}"
      end

      JSON.parse(res.body)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON from #{url}: #{e.message}"
    end
  end
end

