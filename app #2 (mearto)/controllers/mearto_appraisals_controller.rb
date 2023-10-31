# frozen_string_literal: true

class MeartoAppraisalsController < ApplicationController
  before_action :set_item, except: :load_csv
  before_action :set_appraisal, only: %i[edit update add_new_comment]

  def create
    res = MeartoAppraisals::Operations::Create.call(record_params: appraisal_params,
                                                    specialist: current_user, item: @item,
                                                    draft: params['mearto_appraisal']['draft'])
    respond_to do |format|
      if res.success?
        format.html { respond_with @item, res.args[:record], location: item_specialist_path(@item) }
      else
        format.html { redirect_to item_path(@item), alert: 'Could not save appraisal' }
      end
      format.js
    end
  end

  def edit
    render 'edit', layout: false if request.xhr?
  end

  def update
    respond_to do |format|
      res = MeartoAppraisals::Operations::Update.call(record: @appraisal,
                                                      record_params: appraisal_params,
                                                      notify_seller: params['mearto_appraisal']['notify_seller'],
                                                      draft: params['mearto_appraisal']['draft'])
      @appraisal = res.data[:record]
      if res.success?
        format.html { respond_with @item, @appraisal, location: item_specialist_path(@item) }
        format.js { render 'create' }
      else
        format.html { redirect_to item_specialist_path(@item), alert: res.args[:record].errors.full_messages }
        format.js
      end
    end
  end

  def add_new_comment
    @comment = @appraisal.comments.build(comment_params.except(:resolved))
    @comment.user = current_user
    if @comment.save
      @item.in_dialog! if current_user.seller?
      @item.resolved! if comment_params['resolved'] == 'true'
      SendNotifyAboutNewCommentJob.perform_later(@appraisal, @item, current_user)
      NotifierService.new(PostToSlackJob).comment_submitted(current_user, @item)
    else
      flash[:danger] = 'Comment can not be empty'
    end
    respond_with @item, @appraisal, location: item_path(@item)
  end

  def load_csv
    first_date = params[:first_date].to_date if params[:first_date]
    second_date = params[:second_date].to_date if params[:second_date]

    query = Appraisal.where('estimate_max_cents <> 0 AND appraisals.created_at BETWEEN ? AND ?', first_date, second_date)
    appraisals = query.joins(item: :channel).where("channels.name = 'mearto'")

    if appraisals && appraisals.count > 0
      respond_to do |format|
        format.csv { send_data appraisals.to_csv, filename: 'appraisals.csv' }
      end
    else
      redirect_back(fallback_location: '/admin/appraisals_csv', alert: 'There are no appraisals for this period.')
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_item
    @item = Item.friendly.find(params[:item_id])
  end

  def set_appraisal
    @appraisal = MeartoAppraisal.find(params[:id])
  end

  def appraisal_params
    params.require(:mearto_appraisal).permit(:estimate_min, :estimate_max, :description, :notes, :item, :insurance_value,
                                             :currency, :fake, :conditional, :auction_houses_recommendation,
                                             :suggested_asking_price)
  end

  def comment_params
    params.require(:comment).permit(:comment, :title, :resolved)
  end
end
