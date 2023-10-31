class NotifierService
  def initialize(job)
    @job = job
  end

  def exception(msg)
    @job.perform_later msg, channel: '#exceptions'
  end

  def interest_updated(interest)
    @interest = interest
    @identifier = @interest.item.title == nil ? @interest.item.id : @interest.item.slug
    message = "#{@interest.specialist.fullname} #{@interest.interested ? '*IS*' : 'is *NOT*'} interested in <a href='http://www.mearto.com/items/#{@interest.item.id}'>#{@identifier}</a>"
    @job.perform_later message
  end

  def appraisal_given(appraisal)
    @appraisal = appraisal
    @identifier = @appraisal.item.title == nil ? @appraisal.item.id : @appraisal.item.slug
    message = "#{@appraisal.specialist.fullname} gave an appraisal: <a href='http://www.mearto.com/items/#{@identifier}'>#{@identifier}</a>"
    @job.perform_later message
  end

  def authentication_given(authentication)
    @authentication = authentication
    message = "#{@authentication.specialist.fullname} gave an authentication for eBay item #{@authentication.ebay_item.id}"
    @job.perform_later message
  end


  def site_not_found(site, file_url)
    @site = site
    @file_url = file_url
    message = "Site with slug or name #{@site} not found. Analysis aborted for file #{@file_url}"
    @job.perform_later message, channel: '#scraper_data'
  end

  def conditional_appraisal_given(appraisal, update=false)
    @appraisal = appraisal
    @identifier = @appraisal.item.title == nil ? @appraisal.item.id : @appraisal.item.slug
    link = "<a href='http://www.mearto.com/items/#{@identifier}'>#{@identifier}</a>"
    text = update ? "marked aprraisal as conditional: " : "gave an conditional appraisal: "
    message = "#{@appraisal.specialist.fullname} " + text + link
    @job.perform_later message, channel: '#conditionals'
  end

  def comment_submitted(user, item)
    @item = item
    @user = user
    message = "#{@user.fullname} commented on: <a href='http://www.mearto.com/items/#{@item.slug}'>#{@item.title}</a>"
    @job.perform_later message, icon_url: "http://www.freeiconspng.com/uploads/comment-png-31.png", username: 'comment-man'
  end

  def ebay_comment_submitted(user, ebay_item)
    @ebay_item = ebay_item
    @user = user
    message = "#{@user.fullname} commented authentication for #{@ebay_item.id}"
    @job.perform_later message, icon_url: "http://www.freeiconspng.com/uploads/comment-png-31.png", username: 'comment-man'
  end


  def user_would_like_to_sell(user, item)
    @item = item
    @user = user
    message = "#{@user.fullname} would like to sell item: <a href='http://www.mearto.com/items/#{@item.id}'>#{@item.id.split('-')[0]}</a>"
    @job.perform_later message, icon_url: "https://image.freepik.com/free-psd/money-icon-psd-finance-symbol_30-2336.jpg", username: 'money-man'
  end

  def subscription_created(subscription)
    @subscription = subscription
    message = "#{@subscription.stripe_subscription_id} created. <a href='http://www.mearto.com/admin/subscriptions/#{@subscription.id}'>#{@subscription.id.split('-')[0]}</a>"
    @job.perform_later message, channel: '#subscription'
  end

  def subscription_cancelled(subscription)
    @subscription = subscription
    message = "#{@subscription.stripe_subscription_id} cancelled. <a href='http://www.mearto.com/admin/subscriptions/#{@subscription.id}'>#{@subscription.id.split('-')[0]}</a>"
    @job.perform_later message, channel: '#subscription'
  end

  def subscription_failed(subscription)
    @subscription = subscription
    message = "#{@subscription.stripe_subscription_id} failed. <a href='http://www.mearto.com/admin/subscriptions/#{@subscription.id}'>#{@subscription.id.split('-')[0]}</a>"
    @job.perform_later message, channel: '#subscription'
  end

  def mailchimp_failed(exception)
    message = "Mailchimp newsletter insert failed: #{exception.detail}"
    @job.perform_later message
  end

  def sib_newsletter_failed(exception_string)
    message = "Newsletter insert failed: #{exception_string}"
    @job.perform_later message
  end

  def new_seller_for_database(user)
    @user = user
    message = "#{@user.fullname} Signed up for price database (freemium)"
    @job.perform_later message, channel: '#subscription'
  end

  def appraisal_was_bought(item)
    @item = item
    message = "PAID --> #{@item.seller.fullname} (#{@item.channel.name}) bought instant appraisal: <a href='http://www.mearto.com/items/#{@item.slug}'>#{@item.slug}</a>"
    @job.perform_later message, username: 'money-man'
  end

  def authentication_was_bought(ebay_item)
    @ebay_item = ebay_item
    message = "PAID --> #{@ebay_item.seller.fullname} bought instant authentication for eBay item #{@ebay_item.id}"
    @job.perform_later message, username: 'money-man'
  end

  def appraiser_partner(name, email, phone, message)
    message = "Appraiser will like to be contacted: #{name} #{email} #{phone}. Message: #{message}"
    @job.perform_later message, channel: '#sales'
  end

  def credits_were_bought(seller, credits_count)
    message = "PAID --> #{seller.fullname} (#{seller.channel.name}) bought #{credits_count} credits"
    @job.perform_later message, username: 'money-man'
  end

  def consign_alert(name, email, message)
    message = "User would like to consign: #{name} #{email}. Message: #{message}"
    @job.perform_later message, channel: '#sales'
  end

  def new_subscription_created(user, plan)
    @user = user
    message = "#{@user.fullname} subscribed to databases (#{plan.slug}) with credit card"
    @job.perform_later message, channel: '#subscription'
  end

  def subscription_upgraded(user)
    @user = user
    message = "#{@user.fullname} upgraded to Premium"
    @job.perform_later message, channel: '#subscription'
  end

  NotifierService.instance_methods(false).each do |method|
    alias_method "original_#{method.to_s}".to_sym, method
    define_method method do |*args, &block|
      return false if Rails.env.test? || Rails.env.staging?
      send("original_#{method.to_s}".to_sym, *args, &block)
    end
  end
end
