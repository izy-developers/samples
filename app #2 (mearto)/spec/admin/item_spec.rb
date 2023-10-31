# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ItemsController, type: :controller do
  render_views

  let!(:admin) { create(:admin_user) }
  let(:specialist) { create(:user, :specialist) }
  let!(:seller) { create(:user, :seller) }
  before(:each) { sign_in(admin) }
  let(:page) { Capybara::Node::Simple.new(response.body) }

  describe 'PATCH update' do
    context 'manually add a item to marketplace' do
      let!(:item) { create(:item, :create, seller: seller, asking_price: 10, on_marketplace: false, is_for_sale: 'No') }
      let(:do_request) { patch :update, params: { id: item.slug, item: { marketplace_status: 'on' } } }

      it 'returns http success', retry: 1 do
        do_request
        expect(response).to have_http_status(:found)
      end

      it 'returns http success', retry: 1 do
        expect(Item.for_marketplace).to be_empty
        do_request
        expect(Item.for_marketplace).to be_present
      end
    end

    context 'manually remove a item from marketplace' do
      let!(:item) { create(:item, :create, seller: seller, asking_price: 250, on_marketplace: true) }
      let(:do_request) { patch :update, params: { id: item.slug, item: { marketplace_status: 'off' } } }

      it 'returns http success', retry: 1 do
        do_request
        expect(response).to have_http_status(:found)
      end

      it 'returns http success', retry: 1 do
        expect(Item.for_marketplace).to be_present
        do_request
        expect(Item.for_marketplace).to be_empty
      end
    end
  end
end
