class Admin::ModerationsController < Admin::BaseController
  def show
    @scope = params[:scope] || "articles"

    if @scope == "articles"
      @results = Article.kept.joins(:reports)
                        .where(reports: { status: :pending })
                        .distinct
                        .includes(:user, reports: [:user])
                        .order(created_at: :desc)
      @pagy, @results = pagy(@results, items: 10)
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
