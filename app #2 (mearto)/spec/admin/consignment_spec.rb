# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ConsignmentsController, type: :controller do
  render_views

  let!(:admin) { create(:admin_user) }
  let(:specialist) { create(:user, :specialist) }
  let!(:seller) { create(:user, :seller) }
  let!(:item) { create(:item, :create, seller: seller) }
  let!(:organisation) { create(:organisation) }
  let!(:appraisal) do
    create(:mearto_appraisal, item_id: item.id, specialist_id: specialist.id, estimate_min: 5000, estimate_max: 6000)
  end
  before(:each) { sign_in(admin) }
  let(:page) { Capybara::Node::Simple.new(response.body) }

  describe 'GET index' do
    it 'returns http success', retry: 1 do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns the person', retry: 1 do
      get :index
      expect(assigns(:consignments)).to match_array [appraisal]
    end

    it 'should render the expected columns', retry: 1 do
      get :index
      expect(page).to have_content('Estimate Min')
      expect(page).to have_content('Estimate Max')
      expect(page).to have_content('Currency')
    end

    it 'filter Name exists', retry: 1 do
      get :index
      filters_sidebar = page.find('#filters_sidebar_section')
      expect(filters_sidebar).to have_css('label[for="q_estimate_min_cents"]', text: 'Estimate Min')
      expect(filters_sidebar).to have_css('input[name="q[estimate_min_cents_equals]"]')
    end
  end
end
