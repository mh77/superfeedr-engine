# frozen_string_literal: true

require "rack-superfeedr"
require "uri"

module SuperfeedrEngine
  class Engine < ::Rails::Engine
    isolate_namespace SuperfeedrEngine
    mattr_accessor :feed_class

    extend SuperfeedrAPI

    def self.list(opts = {})
      super(opts)
    end

    def self.replay(instance, opts = {})
      validate_url(instance)
      validate_id(instance)

      super instance.url, instance.id, opts
    end

    def self.retrieve(instance, opts = {})
      validate_url(instance)

      opts.merge!(format: "json")

      retrieve_by_topic_url instance.url, opts
    end

    def self.search(query, opts = {})
      opts.merge!(format: "json")

      super query, opts
    end

    def self.subscribe(instance, opts = {})
      validate_url(instance)
      validate_id(instance)
      validate_secret(instance)

      opts.merge!(format: "json", secret: instance.secret)

      super instance.url, instance.id, opts
    end

    def self.unsubscribe(instance, opts = {})
      validate_url(instance)
      validate_id(instance)

      super instance.url, instance.id, opts
    end

    def self.validate_id(instance)
      unless instance.class.method_defined?(:id)
        raise ValidationError, "Missing :id property on #{instance}."
      end

      unless instance.id.present?
        raise ValidationError, "#{instance}#id cannot be empty."
      end
    end

    def self.validate_secret(instance)
      unless instance.class.method_defined?(:secret)
        raise ValidationError, "Missing :secret property on #{instance}."
      end

      unless instance.secret.present?
        raise ValidationError, "#{instance}#secret cannot be empty."
      end
    end

    def self.validate_url(instance)
      unless instance.class.method_defined?(:url)
        raise ValidationError, "Missing :url property on #{instance}."
      end

      unless valid_url?(instance.url)
        raise ValidationError, "#{instance}#url must be a URL."
      end
    end

    def self.valid_url?(url)
      URI.parse(url).kind_of?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end
  end
end
