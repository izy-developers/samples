# frozen_string_literal: true

module Export
  module Admin
    class NewsletterSubscribers
      def initialize(params)
        @params = params
      end

      def self.call(params)
        new(params).call
      end

      def call
        prepare_dates
        fetch_subscribers
        return false unless subscribers.count.positive?

        generate_csv
      end

      private

      attr_reader :params, :start_date, :end_date, :subscribers

      def prepare_dates
        @start_date = (params[:start_date]&.to_datetime || Date.current).beginning_of_day
        @end_date = (params[:end_date]&.to_datetime || Date.current).end_of_day
      end

      def fetch_subscribers
        @subscribers = NewsletterSubscriber.left_outer_joins(:user).by_date_range(start_date, end_date)
      end

      def generate_csv
        CSV.generate(headers: true) do |csv|
          csv << %w[first_name last_name email country city/state created_at]
          subscribers.each do |subscriber|
            csv << [subscriber.user&.first_name] +
                   [subscriber.user&.last_name] +
                   [subscriber.email] +
                   [subscriber.user&.country_name] +
                   [subscriber.user&.address] +
                   [subscriber.created_at]
          end
        end
      end
    end
  end
end
