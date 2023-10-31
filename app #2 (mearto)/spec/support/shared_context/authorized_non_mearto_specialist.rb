RSpec.shared_context "authorized non mearto specialist" do

  before do
    @user = FactoryBot.create(:specialist)
    @department = FactoryBot.create(:department, :auction_house )
    @user.update(department_id: @department.id, consign_access: true)

    visit "/users/sign_in"
    within ".new_user" do
      fill_in :user_email, with: @user.email
      fill_in :user_password, with: @user.password
      click_button "Log in"
    end
  end

  let (:user) { @user }
  let (:department) { @department }
end
