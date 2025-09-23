class Admin::ArticlesController < Admin::BaseController
  before_action :set_article, only: [:destroy, :resolve_reports, :dismiss_reports, :new_hide, :hide, :approve_restoration, :new_rejection, :reject_restoration ]
  def destroy
    @article.reports.pending.update_all(status: :resolved)
    @article.discard
    redirect_to admin_moderation_path, notice: "Article was deleted and reports were resolved."
  end
  def resolve_reports
    @article.reports.pending.update_all(status: :resolved)
    redirect_to admin_moderation_path, notice: "Reports for article were resolved."
  end
  def dismiss_reports
    @article.reports.pending.update_all(status: :dismissed)
    redirect_to admin_moderation_path, notice: "Reports for article were dismissed."
  end
  def new_hide
    authorize @article, :hide?
    respond_to do |format|
      format.turbo_stream
      format.html {
        render turbo_stream: turbo_stream.replace(@article) {
          render partial: "admin/moderations/hide_article_row", article: @article
        }
      }
    end
  end
  def new_rejection
    authorize @article, :hide?
    respond_to do |format|
      format.turbo_stream
      format.html {
        render turbo_stream: turbo_stream.replace(@article) {
          render partial: "admin/moderations/reject_form_row", article: @article
        }
      }
    end
  end

  def hide
    authorize @article, :hide?
    @article.reports.pending.update_all(status: :resolved)
    @article.discard
    record = @article.moderation_records.create!(
      admin: current_user,
      admin_reason: params.dig(:article, :admin_reason),
      status: :hidden
    )
    AuthorNotifierJob.perform_async(record.id, "hidden")
    redirect_to admin_moderation_path, notice: "Article has been hidden."
  end
  def approve_restoration
    authorize @article, :restore?
    if (record = @article.moderation_records.pending_review.last)
      record.update(status: :approved)
      @article.undiscard
      @article.reports.pending.update_all(status: :resolved)
      AuthorNotifierJob.perform_async(record.id, "approved")
      redirect_to admin_moderation_path, notice: "Article restored and request approved."
    else
      redirect_to admin_moderation_path, alert: "Could not find a pending request."
    end
  end
  def reject_restoration
    authorize @article, :hide?
    if (record = @article.moderation_records.pending_review.last)
      record.update(status: :rejected, rejection_reason: params.dig(:article, :rejection_reason))
      AuthorNotifierJob.perform_async(record.id, "rejected")
      redirect_to admin_moderation_path, notice: "Restoration request was rejected."
    else
      redirect_to admin_moderation_path, alert: "Could not find a pending request."
    end
  end

  private
  def set_article
    scope = if action_name.in?(%w[hide new_hide approve_restoration new_rejection reject_restoration])
              Article.all
    else
              Article.kept
    end
    @article = scope.friendly.find(params[:id])
  end
end
