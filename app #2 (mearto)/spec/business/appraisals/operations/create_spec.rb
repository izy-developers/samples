# frozen_string_literal: true

require 'rails_helper'

describe MeartoAppraisals::Operations::Create do
  subject { described_class.call(record_params: appraisal_params, specialist: specialist, item: item) }

  describe '.call' do
    let!(:specialist) { create(:specialist) }
    let!(:item) { create(:item) }

    context 'with valid params for resolved state' do
      let!(:appraisal_params) do
        { estimate_min: 10_000, estimate_max: 20_000, description: 'Test',
          item: item, currency: 'USD', fake: false, conditional: false,
          auction_houses_recommendation: '', suggested_asking_price: nil }
      end

      it 'should create an mearto appraisal' do
        expect(subject.success?).to eq true
        expect(item.mearto_appraisals.count).to eq 1
        expect(item.state).to eq 'resolved'
      end
    end

    context 'with valid params for open state' do
      let!(:appraisal_params) do
        { estimate_min: 0, estimate_max: 0, description: 'Test',
          item: item, currency: 'USD', fake: false, conditional: false,
          auction_houses_recommendation: '', suggested_asking_price: nil }
      end

      it 'should create an mearto appraisal as open' do
        expect(subject.success?).to eq true
        expect(item.mearto_appraisals.count).to eq 1
        expect(item.state).to eq 'open'
      end
    end

    context 'with valid params for draft state' do
      subject { described_class.call(record_params: appraisal_params, specialist: specialist, item: item, draft: '1') }
      let!(:appraisal_params) do
        { estimate_min: 0, estimate_max: 0, description: 'Test',
          item: item, currency: 'USD', fake: false, conditional: false,
          auction_houses_recommendation: '', suggested_asking_price: nil }
      end

      it 'should create an mearto appraisal as draft' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(subject.success?).to eq true
        expect(item.mearto_appraisals.count).to eq 1
        expect(item.state).to eq 'draft'
      end
    end
  end
end
