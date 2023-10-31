# frozen_string_literal: true

module Items
  module Operations
    class ToggleFavourite < BaseOperation
      def call
        within_transaction do
          starred_items.present? ? destroy_starred_items : create_starred_item
          track_action
          success(args)
        end
      end

      private

      attr_reader :user, :ahoy

      def starred_items
        @starred_items ||= record.starred_by?(user)
      end

      def track_action
        ahoy.track "#{starred_items ? 'Moved to' : 'Removed from'} favourite", item_id: record.slug
      end

      def create_starred_item
        user.starred_items.create(item_id: record.id)
      end

      def destroy_starred_items
        user.starred_items.where(item_id: record.id).destroy_all
      end
    end
  end
end
