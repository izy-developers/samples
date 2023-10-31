# frozen_string_literal: true

module GuestUser
  class ClearService
    def initialize(options = {})
      @options = options
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      users.each do |user|
        Schedule.where(user_id: user.id).destroy_all
        Member.where(user_id: user.id).destroy_all
        Announcement.where(user_id: user.id).destroy_all
        user.destroy
      end
    end

    private

    attr_reader :options

    def users
      @users ||= User.all.select { |u| u.email =~ /\b[A-Z0-9._%a-z\-]+@guest\.topsquad\z/ }
    end
  end
end
