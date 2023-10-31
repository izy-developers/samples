# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscription, type: :model do
  context 'Test validation' do
    it 'should be valid' do
      expect(FactoryBot.build(:subscription)).to be_valid
    end
  end

  context 'Test asscociation' do
    it 'should belongs_to plan' do
      expect(Subscription.reflect_on_association(:plan).macro).to eq(:belongs_to)
    end

    it 'should belongs_to user' do
      expect(Subscription.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'should have many payments' do
      expect(Subscription.reflect_on_association(:payments).macro).to eq(:has_many)
    end
  end

  context 'Test scope' do
    let(:seller) { FactoryBot.create(:seller, :mearto_channel) }
    let(:subscription) { FactoryBot.create(:subscription, :active, trial_end: Time.now + 1.day, seller_id: seller.id) }

    it 'is_active should be true' do
      expect(Subscription.is_active).to match_array(Subscription.where('subscription_expires_at >= ?', Time.now))
    end

    it 'is_active_but_has_cancelled should be true' do
      create(:subscription, :active, cancelled_at: Time.now + 1.day)
      expect(Subscription.is_active_but_has_cancelled).to match_array(Subscription.where('subscription_expires_at >= ? and cancelled_at is not null', Time.now))
    end

    it 'is_active_but_has_failed should be true' do
      expect(Subscription.is_active_but_has_failed).to match_array(Subscription.where('subscription_expires_at >= ? and failed_at is not null', Time.now))
    end

    it 'in_trial should be true' do
      expect(Subscription.in_trial).to match_array(Subscription.where('trial_end > ? ', Time.now))
    end

    it 'by_current_user should be true' do
      expect(Subscription.by_current_user(seller)).to match_array(Subscription.where(user: seller).where(active: true))
    end

    it 'subscription_failed should be true' do
      expect(Subscription.subscription_failed(seller)).to match_array(Subscription.where(user: seller).where.not(failed_at: nil))
    end
  end

  context 'Test method' do
    let(:seller) { FactoryBot.create(:seller, :mearto_channel) }
    let(:basic_plan) { FactoryBot.create(:plan, :basic) }
    let(:subscription) { FactoryBot.create(:subscription, :active, seller_id: seller.id, plan_id: basic_plan.id) }

    it 'is_trial? should be false' do
      expect(subscription.is_trial?).to be false
    end

    it 'is_trial? should be true' do
      subscription.trial_end = Time.now + 3.day
      expect(subscription.is_trial?).to be true
    end

    it 'is_trial? should be false' do
      subscription.trial_end = Time.now - 3.day
      expect(subscription.is_trial?).to be false
    end

    it 'has_been_cancelled? should be false' do
      expect(subscription.has_been_cancelled?).to be false
    end

    it 'has_been_cancelled? should be true' do
      subscription.cancelled_at = Time.now + 3.day
      expect(subscription.has_been_cancelled?).to be true
    end

    # check method
    it 'save_and_make_payment should be true' do
      expect(subscription.save_and_make_payment(basic_plan, 'tok_visa', seller, nil)).to be true
    end

    it 'save_and_make_payment should be false' do
      expect(subscription.save_and_make_payment(basic_plan, 'invalid_expiry_year', seller, nil)).to be false
    end

    it 'save_and_make_payment should be true' do
      expect(subscription.save_and_make_payment(basic_plan, 'tok_avsLine1Fail', seller, nil)).to be true
    end

    it 'is_paid_for? should be false' do
      expect(subscription.is_paid_for?).to be false
    end

    it 'is_paid_for? should be true' do
      subscription.stripe_subscription_id = 'sub_EZ0Iq70aF8RtbD'
      subscription.cancelled_at = Time.now + 3.day
      create(:payment, stripe_subscription_id: subscription.stripe_subscription_id)
      expect(subscription.is_paid_for?).to be true
    end

    it 'do_cancel_subscription should be true' do
      customer = Stripe::Customer.create(description: 'Test user', source: 'tok_visa')
      stripe_subscription = Stripe::Subscription.create(customer: customer.id, items: [{ plan: 'basic2' }])
      subscription = create(:subscription, :active, seller_id: seller.id, stripe_subscription_id: stripe_subscription.id)
      expect(subscription.do_cancel_subscription).to be true
    end
  end
end
