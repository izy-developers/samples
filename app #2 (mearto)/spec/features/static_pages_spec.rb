require "rails_helper"

describe "Spec for Static Pages", type: :feature do

  let!(:channel) { FactoryBot.create(:channel) }

  pages = %w[/ /about /contact /appraisers /consign /contact /artists /brands /items]
  context "not signed in" do
    pages.each do |static_page|
      it "#{static_page} should success" do
        visit static_page
        expect(page.status_code).to eq(200)
        expect(page).to have_content "Log in"
      end
    end
  end

  context "signed in" do
    include_context "authorized user"
    it "should succsess" do
      visit '/about'
      expect(page.status_code).to eq(200)
      expect(page).not_to have_content "Log in"
    end
  end
end
