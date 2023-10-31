# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cron::Items::MarkAsResolved do
  subject { described_class.call }

  describe '.call' do
    let!(:channel) { create(:channel) }
    let!(:seller) { create(:seller, channel: channel) }
    let!(:items) { create_list(:item, 3, state: :missing_info, seller: seller) }

    context 'items in missed info for 90 days without comments' do
      let!(:comments) do
        items.each do |item|
          mearto_appraisal = create(:appraisal, item: item)
          create(:comment, commentable_type: 'Appraisal', commentable_id: mearto_appraisal.id, created_at: 91.days.ago, user: seller)
        end
      end

      it 'should mark them as resolved', retry: 1 do
        expect(subject).to eq 3
        expect(Item.where(state: :missing_info).count).to eq 0
      end
    end

    context 'items in missed info with recent comments' do
      let!(:comments) do
        items.each do |item|
          mearto_appraisal = create(:appraisal, item: item)
          create(:comment, commentable_type: 'Appraisal', commentable_id: mearto_appraisal.id, user: seller)
        end
      end

      it 'should not mark them as resolved', retry: 1 do
        expect(subject).to eq 0
        expect(Item.where(state: :missing_info).count).to eq 3
      end
    end
  end
end
