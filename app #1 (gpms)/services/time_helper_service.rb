# frozen_string_literal: true

class TimeHelperService
  def self.for_each_year(from, to, &block)
    for_each_period('yearly', from, to, &block)
  end

  def self.for_each_month(from, to, &block)
    for_each_period('monthly', from, to, &block)
  end

  def self.for_each_day(from, to, reverse = false, &block)
    if reverse
      for_each_period_reverse('daily', from, to, &block)
    else
      for_each_period('daily', from, to, &block)
    end
  end

  def self.for_each_period(type, from, to)
    current = time_frame_beginning(type, from)

    while current <= to
      yield(current, time_frame_end(type, current))
      current += time_frame_unit(type)
    end
  end

  def self.for_each_period_reverse(type, from, to)
    current = time_frame_beginning(type, from)

    while current >= to
      yield(current)
      current -= time_frame_unit(type)
    end
  end

  def self.time_frame_beginning(type, time)
    case type
    when 'daily'
      time.beginning_of_day
    when 'monthly'
      time.beginning_of_month
    when 'yearly'
      time.beginning_of_year
    end
  end

  def self.time_frame_end(type, time)
    case type
    when 'daily'
      time.end_of_day
    when 'monthly'
      time.end_of_month
    when 'yearly'
      time.end_of_year
    end
  end

  def self.time_frame_unit(type)
    case type
    when 'daily'
      1.day
    when 'monthly'
      1.month
    when 'yearly'
      1.year
    end
  end
end
