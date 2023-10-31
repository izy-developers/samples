# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ActiveUser
  protect_from_forgery with: :null_session

  before_action :set_menu_title
  before_action :set_current_schedule

  def set_current_schedule
    @current_schedule = active_user.schedules.find_by(id: session[:schedule_id]) || active_user.create_default_schedule
  end

  def set_menu_title
    @menu_title = 'Schedule'
  end

  def after_sign_in_path_for(_resource_or_scope)
    remove_guest_after_sign_in
    session[:schedule_id] = current_user.schedules.default(current_user.id).id
    root_path
  end
end
