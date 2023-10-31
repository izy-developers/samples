require "rails_helper"

describe "Spec for set seller password from authenticate", type: :feature, js: true, driver: :headless_chrome do

  let!(:channel) { FactoryBot.create(:channel) }
  let(:seller) { FactoryBot.create(:seller, :mearto_channel, pass_token: SecureRandom.uuid, phone: '') }

  before(:each) do
    seller
    visit '?pass_token=' + seller.pass_token
  end

  it "should redirect to set password page" do
    expect(page).to have_content('Welcome to Mearto. Set your password.')
    expect(page).to have_current_path(set_first_password_path, only_path: true)
  end

  it "should set password without item" do
    fill_in :seller_password, with: '123123123'
    fill_in :seller_password_confirmation, with: '123123123'
    click_button 'Submit'

    expect(page).to have_content('Password successfully updated.')
  end
end
