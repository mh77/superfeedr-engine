# frozen_string_literal: true

require "openssl"

require_dependency "superfeedr_engine/application_controller"

module SuperfeedrEngine
  class PubsubhubbubController < ApplicationController
    before_action :ensure_notified_method_exists
    before_action :ensure_feed_exists
    before_action :ensure_signature_exists
    before_action :ensure_algo_is_sha1
    before_action :ensure_signature_matches
    skip_before_action :verify_authenticity_token

    def notify
      update_feed

      render_response
    end

  protected

    def feed_klass
      @feed_klass ||= SuperfeedrEngine::Engine.feed_class.constantize
    end

    def feed_id
      @feed_id ||= params[:feed_id]
    end

    def log_error_and_halt(msg)
      Rails.logger.error("PubsubhubbubControllerException: #{msg} Ignored payload for feed##{feed_id}. Use retrieve to recover this update.")

      render_response
    end

    def render_response
      head :ok
    end

    def update_feed
      case @feed.method(:notified).arity
      when 3; @feed.notified(sanitized_params, request.raw_post, request)
      when 2; @feed.notified(sanitized_params, request.raw_post)
      else;   @feed.notified(sanitized_params)
      end
    end

    def sanitized_params
      params.except(:pubsubhubbub, :feed_id)
    end

  private

    def ensure_notified_method_exists
      return if feed_klass.method_defined?(:notified)

      log_error_and_halt("Please make sure your #{feed_klass} class has a :notified method.")
    end

    def ensure_feed_exists
      return if @feed = feed_klass.where(id: feed_id).take

      log_error_and_halt("Unknown feed##{feed_id}.")
    end

    def ensure_signature_exists
      return if @signature = request.headers["HTTP_X_HUB_SIGNATURE"]

      log_error_and_halt("Missing signature.")
    end

    def ensure_algo_is_sha1
      @algo, @hash = @signature.split("=")

      return if @algo == "sha1"

      log_error_and_halt("Unknown signature mechanism #{@algo}.")
    end

    def ensure_signature_matches
      digest   = OpenSSL::Digest.new(@algo)
      computed = OpenSSL::HMAC.hexdigest(digest, @feed.secret, request.raw_post)

      return if computed == @hash

      log_error_and_halt("Non-matching signature.")
    end
  end
end
