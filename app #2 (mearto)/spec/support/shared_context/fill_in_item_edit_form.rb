RSpec.shared_context 'fill in item edit form' do

  def fill_update_item_form_input(slug, type, new_data)
    visit '/items/' + slug + '/edit'
    fill_in type, with: new_data
    click_button 'Update'
  end
end
