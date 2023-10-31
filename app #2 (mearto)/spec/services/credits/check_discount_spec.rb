# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Credits::CheckDiscount do
  describe 'check custom discount' do
    let!(:admin_user) { create(:admin_user) }
    let!(:seller) { create(:user, :seller) }
    let!(:discount) { create(:discount, kind: 'custom', admin_user: admin_user, value: 50) }
    subject { described_class.call(Seller.find(seller.id), discount) }

    context 'when discount was not used' do
      it 'should return true', retry: 1 do
        expect(subject).to eq true
      end
    end

    context 'when discount was used' do
      before(:each) do
        Seller.find(seller.id).users_discounts.create(discount_id: discount.id)
      end

      it 'should return false', retry: 1 do
        expect(subject).to eq false
      end
    end
  end

  describe 'check referral discount' do
    let!(:seller) { create(:user, :seller) }
    let!(:friend) { create(:user, :seller) }
    let!(:discount) { create(:discount, kind: 'referral', seller_id: seller.id, value: 20) }
    subject { described_class.call(Seller.find(seller.id), discount) }

    context 'when discount was not used by a friend' do
      it 'should return flase', retry: 1 do
        expect(subject).to eq false
      end
    end

    context 'when discount was used by a friend' do
      before(:each) do
        Seller.find(friend.id).users_discounts.create(discount_id: discount.id)
      end

      it 'should return true', retry: 1 do
        expect(subject).to eq true
      end
    end

    context 'a friend is using the discount' do
      subject { described_class.call(Seller.find(friend.id), discount) }

      it 'should return true', retry: 1 do
        expect(subject).to eq true
      end
    end
  end
end
