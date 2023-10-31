# frozen_string_literal: true

require 'rails_helper'

describe MeartoAppraisals::Operations::Update do
  subject do
    described_class.call(record: appraisal,
                         record_params: appraisal_params,
                         notify_seller: notify_seller)
  end

  describe '.call' do
    let!(:specialist) { create(:specialist) }
    let!(:item) { create(:item) }
    let!(:appraisal) { create(:appraisal, specialist: specialist, item: item) }
    let!(:notify_seller) { true }

    context 'with valid params for resolved state' do
      let!(:appraisal_params) do
        { estimate_min: 10_000, estimate_max: 20_000, description: 'Test',
          item: item, currency: 'USD', fake: false, conditional: false,
          auction_houses_recommendation: 'Test test', suggested_asking_price: 15_000 }
      end

      it 'should update an mearto appraisal' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(subject.success?).to eq true
        expect(appraisal.estimate_min.to_i).to eq appraisal_params[:estimate_min]
        expect(appraisal.estimate_max.to_i).to eq appraisal_params[:estimate_max]
        expect(appraisal.suggested_asking_price.to_i).to eq appraisal_params[:suggested_asking_price]
        expect(item.state).to eq 'resolved'
      end
    end

    context 'with valid params for open state' do
      let!(:appraisal_params) do
        { estimate_min: 0, estimate_max: 0, description: 'Test',
          item: item, currency: 'USD', fake: false, conditional: false,
          auction_houses_recommendation: 'Test test', suggested_asking_price: 15_000 }
      end

      it 'should create an mearto appraisal' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(subject.success?).to eq true
        expect(appraisal.estimate_min.to_i).to eq appraisal_params[:estimate_min]
        expect(appraisal.estimate_max.to_i).to eq appraisal_params[:estimate_max]
        expect(appraisal.suggested_asking_price.to_i).to eq appraisal_params[:suggested_asking_price]
        expect(item.state).to eq 'open'
      end
    end

    context 'with valid params for draft state' do
      subject do
        described_class.call(record: appraisal,
                             record_params: appraisal_params,
                             notify_seller: 'false', draft: '0')
      end
      let!(:item) { create(:item, state: :draft) }
      let!(:appraisal) { create(:appraisal, specialist: specialist, item: item) }
      let!(:appraisal_params) do
        { estimate_min: 0, estimate_max: 0, description: 'Test',
          item: item, currency: 'USD', fake: false, conditional: false,
          auction_houses_recommendation: '', suggested_asking_price: 123 }
      end

      it 'should create an mearto appraisal as open' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0)
        expect(subject.success?).to eq true
        expect(item.mearto_appraisals.count).to eq 1
        expect(item.state).to eq 'open'
      end
    end
  end
end
