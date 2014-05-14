module RocketPants
  module Routing

    # Scopes a set of given api routes, allowing for option versions.
    # @param [Hash] options options to pass through to the route e.g. `:module`.
    # @option options [Array<Integer>, Integer] :versions the versions to support
    # @option options [Array<Integer>, Integer] :version the single version to support
    # @raise [ArgumentError] raised when the version isn't provided.
    def rocket_pants(options = {}, &blk)

      options = options.reverse_merge!({
        prefix:           nil,
        required_prefix:  true
      })

      versions = extract_rocket_pants_versions(options)

      versions_regexp = /(#{versions.join("|")})/

      options = options.deep_merge({
        constraints: { version: versions_regexp },
        path:        ':version',
        defaults:    { format: 'json' },
      })


      scope options, &blk
    end

    alias api rocket_pants

    private

      def extract_rocket_pants_versions(options)
        # Validating the format of the version or versions params
        rp_versions = (Array(options.delete(:versions)) + Array(options.delete(:version))).flatten.map(&:to_s)
        parsed_versions = parse_rocket_pants_version_param(rp_versions)
        parsed_versions.each do |version|
          raise ArgumentError, "Got invalid version: '#{version}'" unless version =~ /\A((\*)|([0-9]+(\.((\*)|([0-9]+(\.((\*)|([0-9]+)))?)))?))\z/
        end
        # Creating the composed routes
        versions = compose_rocket_pants_versions(parsed_versions, options[:prefix], options[:required_prefix])
        raise ArgumentError, 'Please provide atleast one version' if versions.empty?
        versions
      end

      def parse_rocket_pants_version_param(versions)
        versions = [] if versions.is_a?(NilClass)
        versions = [versions] if versions.is_a?(String) || versions.is_a?(Fixnum) || versions.is_a?(Float)
        versions = versions.values if versions.is_a?(Hash)
        versions = versions.to_a if versions.is_a?(Range)
        versions.flatten.to_a.map! {|v| v.to_s}.uniq
      end

      def compose_rocket_pants_versions(parsed_versions, prefix, required_prefix)
        versions = parsed_versions.inject([]) do |acc, version|
          acc << (prefix.blank? ? "#{version}" : "#{prefix}#{version}")
          acc << version if !prefix.blank? && required_prefix.blank?
          acc
        end
        versions.uniq
      end

  end
end