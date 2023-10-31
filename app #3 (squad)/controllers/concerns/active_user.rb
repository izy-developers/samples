# frozen_string_literal: true

module ActiveUser
  extend ActiveSupport::Concern

  included do
    def active_user
      current_user || guest_user
    end

    helper_method :active_user

    def guest_user
      @guest_user ||= User.find_by(id: session[:guest_user_id]) || create_guest_user
    end

    def create_guest_user
      u = User.new(
        email: "guest_#{Time.now.to_i}#{rand(100)}@guest.topsquad",
        first_name: 'Squad',
        last_name: 'Sandbox'
      )
      u.save!(validate: false)
      session[:guest_user_id] = u.id
      # GuestUser::SeedDataService.call(u)
      u
    end

    def user_guest?
      active_user.email.include?('guest.topsquad')
    end

    private

    def remove_guest_after_sign_in
      return unless current_user && session[:guest_user_id] && (session[:guest_user_id] != current_user.id)

      remove_related_entities
      User.find_by(id: session[:guest_user_id])&.destroy
      session[:guest_user_id] = nil
    end

    def remove_related_entities
      Schedule.where(user_id: session[:guest_user_id]).destroy_all
      Member.where(user_id: session[:guest_user_id]).destroy_all
      Announcement.where(user_id: session[:guest_user_id]).destroy_all
    end
  end
end
