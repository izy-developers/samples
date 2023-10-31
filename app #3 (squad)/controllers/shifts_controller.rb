# Actions:
# Creating a new shift from the employees rooster
# Reassigning shift to another eomployee
# Deleting a shift
# Duplicating an entire week of shifts

# Creating a shift:
# Should consider the week availability of the employee
# Should consider that the employee is not already working that day on that hour

class ShiftsController < ApplicationController
  
  # def index
  #   # List all shifts for the current week for given schedule
  #   # Receives a day and extracts start and end of week
  #   @date = params[:date].to_date rescue Date.today
  #   shifts = @current_schedule.shifts.where('start_at >= ? AND start_at <= ?', @date.beginning_of_week, @date.end_of_week)
  #   render json: {success: true, shifts: shifts}
  # end

  def new
    @date = Date.strptime(params[:date],'%Y-%m-%d') rescue Date.today
    @shift = Shift.new
    @members = @current_schedule.members.active
    render 'new', layout: false
  end

  def edit
    @date = params[:date].to_date rescue Date.today
    @shift_id = params[:id]
    @shift = Shift.find params[:id]
    @shift_date = @shift.start_at_date
    @members = @current_schedule.members.active
    render 'edit', layout: false
  end

  def publish
    @date = params[:date]&.to_date || Date.today
    @shifts = @current_schedule.shifts.where('start_at >= ? AND start_at <= ?', @date.beginning_of_week, @date.end_of_week)
    schedule_members = @current_schedule.members.active.ids
    shift_members = @shifts.map(&:member).uniq.map(&:id)
    @no_shift_members = schedule_members - shift_members
    member_ids = shift_members + @no_shift_members
    @members = Member.includes([avatar_attachment: :blob])
                     .where(id: member_ids)
                     .index_by(&:id)
                     .values_at(*member_ids)

    @send_copy_email = current_user&.send_copy_email
    render 'publish', layout: false
  end

  # POST /shifts/add_update
  # {
  #   shift_update: {shift_id: 1, start_at: ... }
  #   new_shifts: [{date: 'YYYY-MM-DD', start_at: '10:00', end_at: '23:30' }, ... ]
  #   delete_shift: 1
  # }
  def add_update
    # Delete shift if present
    shifts = []
    if params[:delete_shift].present?
      shift = @current_schedule.shifts.find_by(id: params[:delete_shift])
      raise "Could not destroy shift #{shift.id}" if !shift.destroy
    end
    # Update shift if present
    if params[:shift_update].present?
      shift = @current_schedule.shifts.find_by(id: params[:shift_update][:shift_id])
      day = DateTime.strptime(shift.start_at_date,'%Y-%m-%d')
      shift.start_at = day.change(hour: params[:shift_update][:start_at].split(':')[0].to_i, min: params[:shift_update][:start_at].split(':')[1].to_i)
      shift.end_at = day.change(hour: params[:shift_update][:end_at].split(':')[0].to_i, min: params[:shift_update][:end_at].split(':')[1].to_i)
      shift.end_at += 1.day if params[:shift_update][:end_at] == '00:00'
      if shift.changed?
        raise "Could not save shift #{shift.id}" if !shift.save
        # shifts << shift
      end
    end
    # Create new shifts if present
    if params[:new_shifts].present?
      params[:new_shifts].each do |shift_param|
        shift = @current_schedule.shifts.new(member_id: shift_param[:member_id])
        day = DateTime.strptime(shift_param[:date],'%Y-%m-%d')
        shift.start_at = day.change(hour: shift_param[:start_at].split(':')[0].to_i, min: shift_param[:start_at].split(':')[1].to_i)
        shift.end_at = day.change(hour: shift_param[:end_at].split(':')[0].to_i, min: shift_param[:end_at].split(':')[1].to_i)
        shift.end_at += 1.day if shift_param[:end_at] == '00:00'
        raise "Could not save shift #{shift.id}" if !shift.save
        shifts << shift
      end
    end
    render json: {success: true, shifts: shifts}
  end

  # POST /shifts
  # {
  #   member_id: 1,
  #   shifts: [
  #     {date: '31/12/2023', start_at: '00:00', end_at: '00:00'},
  #   ]
  # }
  def create
    errors = []
    member = @current_schedule.members.find_by(id: params[:member_id])
    shifts = params[:shifts]
    created_shifts = []
    if shifts
      shifts.each do |shift_param|
        shift = member.shifts.new(schedule_id: @current_schedule.id)
        day = DateTime.strptime(shift_param[:date],'%Y-%m-%d')
        if shift_param[:start_at].blank? and shift_param[:end_at].blank? # Should create a shift with the default hours
          # Default hours
          shift.start_at = day.change(hour: 00)
          shift.end_at = day.change(hour: 00) + 1.day
        else
          shift.start_at = day.change(hour: shift_param[:start_at].split(':')[0].to_i, min: shift_param[:start_at].split(':')[1].to_i)
          shift.end_at = day.change(hour: shift_param[:end_at].split(':')[0].to_i, min: shift_param[:end_at].split(':')[1].to_i)
          shift.end_at += 1.day if shift_param[:end_at] == '00:00'
        end
        if shift.save
          created_shifts << shift
        else
          errors << shift.errors.full_messages
        end
      end
      success = created_shifts.any?
      message = "#{created_shifts.count} shifts created"
    else
      success = false
      message = "No shifts created"
    end
    render json: {success: success, message: message, errors: errors, created_shifts: created_shifts}
  end

  def update
    shift = @current_schedule.shifts.find_by(id: params[:id])
    if shift.blank?
      render json: {success: false, message: 'Invalid shift ID'}
    else
      if params[:shift][:day].present? # Shift update from calendar drag and drop
        # Change the day part of the whole date only.
        day = DateTime.strptime(params[:shift][:day],'%Y-%m-%d')
        shift.start_at = shift.start_at.change(day: day.day, month: day.month, year: day.year)
        shift.end_at = shift.end_at.change(day: day.day, month: day.month, year: day.year)
        shift.end_at += 1.day if shift.end_at.hour == 0
      elsif params[:shift][:start_at].include?(':') # From the range slider
        # Change only the hours
        shift.start_at = "#{shift.start_at_date} #{params[:shift][:start_at]}" if params[:shift][:start_at].present?
        shift.end_at = "#{shift.start_at_date} #{params[:shift][:end_at]}" if params[:shift][:end_at].present? # Note how it uses the same start_at_date
        shift.end_at += 1.day if shift.end_at.hour == 0
      end
      # Update the member AKA: Transfer shift
      shift.member_id = params[:shift][:member_id] if params[:shift][:member_id].present?
      if shift.save
        success = true
        message = 'Shift updated successfully'
      else
        puts "-> #{shift.errors.full_messages}"
        success = false
        message = "The shift was not updated. #{shift.errors.full_messages}"
      end
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { render json: {success: success, message: message, shift: shift} }
      end
    end
  end

  def availability # Is this used?
    render json: {success: true, availability: current_user.members_availability}
  end

  def destroy
    shift = @current_schedule.shifts.find_by(id: params[:id])
    if shift.blank?
      render json: {success: false, message: 'Invalid shift ID'}
    else
      if shift.destroy
        render json: {success: true}
      else
        render json: {success: false, message: "The shift was not deleted. #{shift.errors.full_messages}"}
      end
    end
  end

  def update_send_email
    current_user.update(send_copy_email: params[:send_copy_email])
    @send_copy_email = current_user.send_copy_email
    @success = true
  end

  def publish_schedule
    date = DateTime.strptime(params[:date],'%Y-%m-%d')
    return @success = true if user_masquerade? || user_guest?

    @errors = []
    params[:members].each do |member_param|
      member = @current_schedule.members.find_by(id: member_param[:id])
      if member.present?
        member.email = member_param[:email] if member_param[:email].present?
        member.cellphone = member_param[:cellphone] if member_param[:cellphone].present?
        if !member.save
          @errors << {id: member.id, errors: member.errors.full_messages}
        end
      end
    end
    if @errors.blank?
      @success = true
      params[:members].each do |member_param|
        member = @current_schedule.members.find_by(id: member_param[:id])
        if member.present?
          ScheduleMailer.schedule_email(member.id, params[:date], current_user, @current_schedule).deliver_now if member_param[:notify_email] && member.email.present?
          # TODO: Extract this
          if member_param[:notify_sms] and member.cellphone.present?
            body = Messaging::Shift.generate_body(member,@current_schedule,date)
            SendSmsJob.perform_now(body, member.cellphone) if member.cellphone.present? and body.present?
          end
        end
      end
    else
      @success = false
    end
  end

  def duplicate
    date = params[:date].to_date || Date.today rescue Date.today
    # Search for all shifts of the previous week
    shifts = @current_schedule.shifts.where(start_at: (date.beginning_of_week - 1.week).beginning_of_day..(date.end_of_week - 1.week).end_of_day)
    if shifts.any?
      # Search shifts of the current week and delete them
      # @current_schedule.shifts.where(start_at: date.beginning_of_week.beginning_of_day, end_at: date.end_of_week.end_of_day).delete_all
      @current_schedule.shifts.where('start_at >= ? AND end_at <= ?', date.beginning_of_week.beginning_of_day, date.end_of_week.end_of_day).delete_all
      # Duplicate shifts of the previous week in the current week
      shifts.each do |shift|
        @current_schedule.shifts.create(member_id: shift.member_id, start_at: shift.start_at + 1.week, end_at: shift.end_at + 1.week)
      end
      # flash[:notice] = 'Schedule duplicated successfully'
    else
      # flash[:notice] = 'There were no shifts last week to duplicate'
    end
    render json: {success: true}
  end

  def destroy_member
    date = DateTime.strptime(params[:date],'%Y-%m-%d')
    params[:member_ids].each do |member_id|
      shifts = @current_schedule.shifts.where(member_id: member_id, start_at: date.to_date.beginning_of_week.beginning_of_day..date.to_date.end_of_week.end_of_day)
      shifts.destroy_all
    end
    # flash[:notice] = 'Members deleted successfully'
    render json: {success: true}
  end

  def totals_by_week
    # Get the budget for the shifts of the selected week and schedule
    date = DateTime.strptime(params[:date],'%Y-%m-%d') rescue Date.today
    shifts = @current_schedule.shifts.where(start_at: date.beginning_of_week.beginning_of_day..date.end_of_week.end_of_day)
    members = shifts.map{|s| s.member}.uniq
    totals = {
      monday_hours: shifts.select{|s| s[:start_at].strftime('%A') == 'Monday'}.map{|s| s.hours}.sum,
      monday_budget: shifts.select{|s| s[:start_at].strftime('%A') == 'Monday'}.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum,
      tuesday_hours: shifts.select{|s| s[:start_at].strftime('%A') == 'Tuesday'}.map{|s| s.hours}.sum,
      tuesday_budget: shifts.select{|s| s[:start_at].strftime('%A') == 'Tuesday'}.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum,
      wednesday_hours: shifts.select{|s| s[:start_at].strftime('%A') == 'Wednesday'}.map{|s| s.hours}.sum,
      wednesday_budget: shifts.select{|s| s[:start_at].strftime('%A') == 'Wednesday'}.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum,
      thursday_hours: shifts.select{|s| s[:start_at].strftime('%A') == 'Thursday'}.map{|s| s.hours}.sum,
      thursday_budget: shifts.select{|s| s[:start_at].strftime('%A') == 'Thursday'}.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum,
      friday_hours: shifts.select{|s| s[:start_at].strftime('%A') == 'Friday'}.map{|s| s.hours}.sum,
      friday_budget: shifts.select{|s| s[:start_at].strftime('%A') == 'Friday'}.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum,
      saturday_hours: shifts.select{|s| s[:start_at].strftime('%A') == 'Saturday'}.map{|s| s.hours}.sum,
      saturday_budget: shifts.select{|s| s[:start_at].strftime('%A') == 'Saturday'}.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum,
      sunday_hours: shifts.select{|s| s[:start_at].strftime('%A') == 'Sunday'}.map{|s| s.hours}.sum,
      sunday_budget: shifts.select{|s| s[:start_at].strftime('%A') == 'Sunday'}.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum,
    }
    totals[:total_budget] = totals[:monday_budget] + totals[:tuesday_budget] + totals[:wednesday_budget] + totals[:thursday_budget] + totals[:friday_budget] + totals[:saturday_budget] + totals[:sunday_budget]
    totals.keys.select{|k| k.to_s.include?('budget')}.each do |key|
      totals[key] = ActionController::Base.helpers.number_to_currency(totals[key])
    end
    members_budget = []
    members.each do |member|
      budget_object = { member_id: member.id}
      members_shift = shifts.select{|s| s.member_id == member.id}
      budget_object[:budget] = members_shift.map{|s| (s.hours * s.member.hourly_rate) rescue 0 }.sum
      budget_object[:hours] = members_shift.map{|s| s.hours}.sum
      members_budget << budget_object
    end
    render json: {success: true, totals: totals, members_budget: members_budget}
  end

  private
  def shift_params
    params.require(:shift).permit(:start_at, :end_at, :member_id)
  end
end
