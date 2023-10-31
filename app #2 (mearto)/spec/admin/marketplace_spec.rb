# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::MarketplaceItemsController, type: :controller do
  render_views

  let!(:admin) { create(:admin_user) }
  let(:specialist) { create(:user, :specialist) }
  let!(:seller) { create(:user, :seller) }
  before(:each) { sign_in(admin) }
  let(:page) { Capybara::Node::Simple.new(response.body) }

  describe 'GET index' do
    context 'item is for sale' do
      let!(:item) { create(:item, :create, seller: seller, asking_price: 250, on_marketplace: true) }

      it 'should returns http success', retry: 1 do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'should assigns the marketplace_items', retry: 1 do
        get :index
        expect(assigns(:marketplace_items)).to match_array [item]
        expect(page).not_to have_css('tr[id="' + item.id + '"]')
        expect(page).not_to have_content('There are no Marketplace Items yet')
      end

      it 'should render the expected columns', retry: 1 do
        get :index
        expect(page).to have_content('Asking Price')
        expect(page).to have_content('Marketplaced Manually At')
        expect(page).to have_content('Messages')
      end

      it 'filter Name should exists', retry: 1 do
        get :index
        filters_sidebar = page.find('#filters_sidebar_section')
        expect(filters_sidebar).to have_css('label[for="asking_price_cents_gteq_numeric"]', text: 'Asking price range (in cents)')
        expect(filters_sidebar).to have_css('input[name="q[has_appraisals_in][]"]')
      end
    end

    context 'item is not for sale' do
      let!(:item) { create(:item, :create, seller: seller, asking_price: 250, on_marketplace: true, is_for_sale: 'No') }

      it 'should returns http success', retry: 1 do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'should not assign the marketplace_items', retry: 1 do
        get :index
        expect(assigns(:marketplace_items)).not_to match_array [item]
        expect(page).not_to have_css('tr[id="' + item.id + '"]')
        expect(page).to have_content('There are no Marketplace Items yet')
      end
    end

    context 'item asking price is lower than marketplace limit' do
      let!(:item) { create(:item, :create, seller: seller, asking_price: 10, on_marketplace: true, is_for_sale: 'Yes') }

      it 'should returns http success', retry: 1 do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'should not assign the marketplace_items', retry: 1 do
        get :index
        expect(assigns(:marketplace_items)).not_to match_array [item]
        expect(page).not_to have_css('tr[id="' + item.id + '"]')
        expect(page).to have_content('There are no Marketplace Items yet')
      end
    end
  end
end
