# frozen_string_literal: true

RSpec.shared_context 'fill in message form' do
  def fill_message_form(slug, text)
    visit '/items/' + slug
    fill_in :conversation_messages_attributes_0_body, with: text
    click_button 'Send message'
  end
end
