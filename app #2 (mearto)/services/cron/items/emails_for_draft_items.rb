# frozen_string_literal: true

module Cron
  module Items
    class EmailsForDraftItems < BaseAction
      def call
        items = find_items(days_count: 3)
        items.each do |item|
          next if item.seller.guest?
          DraftItemsMailer.three_days_email(item: item).deliver_now
        end

        items = find_items(days_count: 7)
        items.each do |item|
          next if item.seller.guest?
          DraftItemsMailer.seven_days_email(item: item).deliver_now
        end

        items = find_items(days_count: 10)
        items.each do |item|
          next if item.seller.guest?
          DraftItemsMailer.ten_days_email(item: item).deliver_now
        end
      end

      private

      def find_items(days_count:)
        Item.where(state: :draft, created_at: days_count.days.ago.all_day)
      end
    end
  end
end
