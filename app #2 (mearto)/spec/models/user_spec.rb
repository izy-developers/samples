# frozen_string_literal: true

require 'rails_helper'
require 'stripe'

RSpec.describe User, type: :model do
  context 'Test validation' do
    it 'should be valid' do
      expect(FactoryBot.build(:user)).to be_valid
    end
  end

  context 'Test asscociation' do
    it 'should belong_to channel' do
      expect(User.reflect_on_association(:channel).macro).to eq(:belongs_to)
    end

    it 'should have many messages' do
      expect(User.reflect_on_association(:messages).macro).to eq(:has_many)
    end

    it 'should have many conversations_as_sender' do
      expect(User.reflect_on_association(:conversations_as_sender).macro).to eq(:has_many)
    end

    it 'should have many conversations_as_recipient' do
      expect(User.reflect_on_association(:conversations_as_recipient).macro).to eq(:has_many)
    end

    it 'should have many invoices' do
      expect(User.reflect_on_association(:invoices).macro).to eq(:has_many)
    end
  end

  context 'Test method' do
    let(:user) { FactoryBot.build(:user) }
    let(:user_seller) { FactoryBot.create(:user, :seller) }
    let(:seller) { FactoryBot.create(:seller, :mearto_channel) }
    let(:item) { FactoryBot.create(:item, :create, seller_id: seller.id) }
    let(:basic_plan) { FactoryBot.create(:plan, :basic) }

    it 'cancel_subscription should nil' do
      expect(seller.cancel_subscription).to be nil
    end

    it 'cancel_subscription should false' do
      customer = Stripe::Customer.create(description: 'Test user', source: 'tok_visa')
      subscription = Stripe::Subscription.create(customer: customer.id, items: [{ plan: 'basic2' }])
      FactoryBot.create(:subscription, :active, seller_id: seller.id, stripe_subscription_id: subscription.id)
      expect(seller.cancel_subscription).to be true
    end

    it 'conversations should true' do
      FactoryBot.create(:conversation, sender_id: seller.id, recipient_id: seller.id, item_id: item.id)
      expect(seller.conversations).not_to be be_empty
    end

    it 'conversations should empty' do
      expect(user.conversations).to be_empty
    end

    it 'fullname should full name' do
      expect(user.fullname).to eq(user.first_name + ' ' + user.last_name)
    end

    it 'fullname should first name' do
      user.last_name = nil
      expect(user.fullname).to eq(user.first_name + ' ')
    end

    it 'fullname should unknow' do
      user.first_name = nil
      expect(user.fullname).to eq('Unknown')
    end

    it 'webhook_data should true' do
      expect(seller.webhook_data[:email]).to eq(seller.email)
    end

    it 'has_conversation? should true' do
      FactoryBot.create(:conversation, sender_id: seller.id, recipient_id: seller.id, item_id: item.id)
      expect(seller.has_conversation?(item)).to be true
    end

    it 'has_conversation? should false' do
      expect(seller.has_conversation?(item)).to be false
    end

    it 'seller? should true' do
      expect(seller.seller?).to be true
    end

    it 'seller? should false' do
      expect(user.seller?).to be false
    end

    it 'specialist? should true' do
      user = FactoryBot.build(:user, :specialist)
      expect(user.specialist?).to be true
    end

    it 'specialist? should false' do
      expect(user.specialist?).to be false
    end

    it 'god? should true' do
      user = FactoryBot.build(:user, :god)
      expect(user.god?).to be true
    end

    it 'god? should false' do
      expect(user.god?).to be false
    end

    it 'has_active_subscription? should true' do
      FactoryBot.create(:subscription, :active, seller_id: seller.id)
      expect(seller.has_active_subscription?).to be true
    end

    it 'has_active_subscription? should false' do
      expect(seller.has_active_subscription?).to be false
    end

    it 'subscription_type should present' do
      FactoryBot.create(:subscription, :active, seller_id: seller.id, plan_id: basic_plan.id)
      expect(seller.subscription_type).to eq(basic_plan.slug)
    end

    it 'subscription_type should nil' do
      expect(seller.subscription_type).to be nil
    end

    it 'subscription_type_is_premium should nil' do
      expect(seller.subscription_type_is_premium).to be nil
    end

    it 'subscription_type_is_premium should empty' do
      FactoryBot.create(:subscription, :active, seller_id: seller.id, plan_id: basic_plan.id)
      expect(seller.subscription_type_is_premium).to be false
    end

    it 'subscription_type_is_premium should true' do
      plan = FactoryBot.create(:plan, :premium)
      FactoryBot.create(:subscription, :active, seller_id: seller.id, plan_id: plan.id)
      expect(seller.subscription_type_is_premium).to be true
    end

    it 'active_subscription should present' do
      subscription = FactoryBot.create(:subscription, :active, seller_id: seller.id)
      expect(seller.active_subscription).to eq(subscription)
    end

    it 'active_subscription should nil' do
      expect(seller.active_subscription).to be false
    end

    it 'is_premium? should true' do
      expect(user.is_premium?).to be true
    end

    it 'is_premium? should true' do
      FactoryBot.create(:subscription, :active, seller_id: seller.id)
      expect(seller.is_premium?).to be true
    end

    it 'is_premium? should false' do
      expect(seller.is_premium?).to be false
    end

    it 'reset_billy_id should true' do
      expect(seller.send(:reset_billy_id)).to be true
    end
  end
end
