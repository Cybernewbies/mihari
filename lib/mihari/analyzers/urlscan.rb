# frozen_string_literal: true

require "urlscan"

module Mihari
  module Analyzers
    class Urlscan < Base
      attr_reader :title
      attr_reader :description
      attr_reader :query
      attr_reader :tags

      attr_reader :filter
      attr_reader :target_type
      attr_reader :use_pro
      attr_reader :use_similarity

      def initialize(
        query,
        description: nil,
        filter: nil,
        tags: [],
        target_type: "url",
        title: nil,
        use_pro: false,
        use_similarity: false
      )
        super()

        @query = query
        @title = title || "urlscan lookup"
        @description = description || "query = #{query}"
        @tags = tags

        @filter = filter
        @target_type = target_type
        @use_pro = use_pro
        @use_similarity = use_similarity

        raise InvalidInputError, "type should be url, domain or ip." unless valid_target_type?
      end

      def artifacts
        result = search
        return [] unless result

        results = result.dig("results") || []
        results.map do |match|
          match.dig "page", target_type
        end.compact.uniq
      end

      private

      def config_keys
        %w(urlscan_api_key)
      end

      def api
        @api ||= ::UrlScan::API.new(Mihari.config.urlscan_api_key)
      end

      def search
        return api.pro.similar(query) if use_similarity
        return api.pro.search(query: query, filter: filter, size: 10_000) if use_pro

        api.search(query, size: 10_000)
      end

      def valid_target_type?
        %w(url domain ip).include? target_type
      end
    end
  end
end
