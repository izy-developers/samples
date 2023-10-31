# frozen_string_literal: true

RSpec.shared_context 'fill in appraisal form' do
  def fill_appraisal_form(max_cost, type)
    fill_in :mearto_appraisal_estimate_min, with: 10
    fill_in :mearto_appraisal_estimate_max, with: max_cost
    fill_in :mearto_appraisal_description, with: FFaker::Lorem.paragraph
    click_button type
  end

  def update_appraisal(max_cost, form)
    fill_in :mearto_appraisal_estimate_max, with: max_cost
    fill_in :mearto_appraisal_description, with: FFaker::Lorem.paragraph
    within form do
      click_button 'Update'
    end
  end
end
