class Admin::ModerationsController < Admin::BaseController
  def show
    @scope = params[:scope] || "articles"

    if @scope == "articles"
      reported_ids = Report.pending.where(reportable_type: 'Article').pluck(:reportable_id)
      review_ids = ModerationRecord.pending_review.pluck(:article_id)
      all_ids = (reported_ids + review_ids).uniq

      scope = Article.with_discarded.where(id: all_ids)
                     .includes(:user, reports: [:user], moderation_records: [:admin])
                     .order(updated_at: :desc)
      @pagy, @results = pagy(scope)
    elsif @scope == "comments"
      @results = Comment.kept.joins(:reports)
                        .where(reports: { status: :pending })
                        .distinct
                        .includes(:user, :article, reports: [:user])
                        .order(created_at: :desc)
      @pagy, @results = pagy(@results, items: 10)
    end
  end

end
