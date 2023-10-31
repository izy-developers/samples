# frozen_string_literal: true

module Stripe
  module Webhooks
    module Subscriptions
      # Subscription will automatically stop when it expires
      class Deleted < BaseAction
        def call
          log_event
          if !subscription.nil?
            send_notifications
          else
            logger.warn 'SUBSCRIPTION OTHER'
            logger.warn event
          end
        end

        attr_reader :event

        def log_event
          logger.info 'Subscription in task deleted: ' + event.data.object.id
        end

        def subscription
          @subscription ||= ::Subscription.find_by(stripe_subscription_id: event.data.object.id)
        end

        def send_notifications
          MessageMailer.subscription_cancelled(subscription.user, subscription).deliver_later
          NotifierService.new(PostToSlackJob).subscription_cancelled(subscription) unless Rails.env.development?
        end
      end
    end
  end
end
