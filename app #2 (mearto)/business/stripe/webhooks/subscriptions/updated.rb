module Stripe
  module Webhooks
    module Subscriptions
      class Updated < BaseAction
        def call
          logger.info 'Subscription updated: ' + event.data.object.id
          update_subscription if subscription && plan
        end

        attr_reader :event

        def subscription
          @subscription ||= ::Subscription.find_by(stripe_subscription_id: event.data.object.id)
        end

        def plan
          @plan ||= ::Plan.find_by_stripe_id(event.data.object.plan.id)
        end

        def update_subscription
          subscription.subscription_expires_at = Time.at(event.data.object.current_period_end).to_datetime
          subscription.trial_start = Time.at(event.data.object.trial_start).to_datetime if event.data.object.trial_start
          subscription.trial_end = Time.at(event.data.object.trial_end).to_datetime if event.data.object.trial_end
          subscription.plan_id = plan.id
          subscription.save
        end
      end
    end
  end
end
