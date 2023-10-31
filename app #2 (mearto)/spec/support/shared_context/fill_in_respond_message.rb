# frozen_string_literal: true

RSpec.shared_context 'fill in respond message' do
  def respond_to_message(id, text)
    visit '/messages/' + id
    fill_in :message_body, with: text
    click_button 'Send message'
  end
end
