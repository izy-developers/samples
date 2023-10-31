# frozen_string_literal: true

class SandboxController < HomeController
  before_action :masquerade_user!
  before_action :masquerade_authorized_user, :generate_seed_data, only: %i[index]

  private

  def generate_seed_data
    if user_guest?
      Tracker.create(page: 'sandbox', created_at: Time.zone.now)
      GuestUser::SeedDataService.call(active_user)
    end
  end

  def masquerade_authorized_user
    redirect_to masquerade_path(guest_user) if current_user && !user_guest?
  end
end
