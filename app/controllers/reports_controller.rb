class ReportsController < ApplicationController
  before_action :require_login
  before_action :set_reportable

  def new
    @report = @reportable.reports.new
  end

  def create
    @report = @reportable.reports.new(report_params)
    @report.user = current_user
    authorize @report

    if @report.save
      redirect_to reportable_redirect_path, notice: "Thank you! Your report has been submitted for review."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
  def set_reportable
    if params[:comment_id]
      @reportable = Comment.find(params[:comment_id])
    elsif params[:article_id]
      @reportable = Article.friendly.find(params[:article_id])
    end
  end
  def reportable_redirect_path
    if @reportable.is_a?(Article)
      article_path(@reportable)
    else # It's a Comment
      article_path(@reportable.article)
    end
  end

  def report_params
    params.require(:report).permit(:reason)
  end
end
