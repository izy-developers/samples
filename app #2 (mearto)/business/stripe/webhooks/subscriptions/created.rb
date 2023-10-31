module Stripe
  module Webhooks
    module Subscriptions
      class Created < BaseAction
        def call
          if subscription
            update_subscription
            send_notifications
          else
            subscription_not_found
          end
        end

        attr_reader :event

        def subscription
          @subscription ||= ::Subscription.find_by(stripe_subscription_id: event.data.object.id)
        end

        def update_subscription
          subscription.subscription_expires_at = Time.at(event.data.object.current_period_end).to_datetime
          subscription.trial_start = Time.at(event.data.object.trial_start).to_datetime
          subscription.trial_end = Time.at(event.data.object.trial_end).to_datetime
          subscription.save
        end

        def send_notifications
          MessageMailer.subscription_created(subscription.user, subscription).deliver_later
          NotifierService.new(PostToSlackJob).subscription_created(subscription) unless Rails.env.development?
        end

        def subscription_not_found
          msg = 'Subscription could not be created ' + event.data.object.id + ' investigate in Stripe!'
          logger.warn msg
        end
      end
    end
  end
end
