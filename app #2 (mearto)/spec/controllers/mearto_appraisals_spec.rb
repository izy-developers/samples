# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MeartoAppraisalsController, type: :controller do
  describe 'POST create' do
    let(:specialist) { create(:user, :specialist) }
    let!(:seller) { create(:user, :seller) }
    let!(:item) { create(:item, :create, seller: seller) }
    let!(:appraisal_params) do
      { mearto_appraisal: { currency: 'USD', estimate_min: '500000',
                            estimate_max: '600000',
                            description: 'Description',
                            fake: '0',
                            conditional: '0',
                            auction_houses_recommendation: 'Test 1' }, item_id: item.slug }
    end

    before(:each) do
      sign_in(specialist)
    end

    context 'consign by hand' do
      it 'should create new appraisal for the item', retry: 1 do
        get :create, params: appraisal_params, xhr: true
        expect(Appraisal.count).to eq 1
        expect(response.status).to eq 200
      end
    end
  end
end
