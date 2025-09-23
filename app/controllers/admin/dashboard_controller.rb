class Admin::DashboardController < Admin::BaseController
  def index
    # Overview Cards Data
    @total_users = User.count
    @total_articles = Article.count
    @total_comments = Comment.count
    @total_claps = Clap.count
    # Chartkick Data (grouped by the week they were created)
    @users_per_week = User.group_by_week(:created_at).count
    @articles_per_week = Article.group_by_week(:created_at).count
    # Moderation Queue (10 most recent pending reports)
    # @pending_reports = Report.pending.includes(:user, reportable: [:user]).order(created_at: :desc).limit(10)
    reported_article_ids = Report.pending.where(reportable_type: 'Article').pluck(:reportable_id)
    review_article_ids = ModerationRecord.pending_review.pluck(:article_id)
    all_article_ids = (reported_article_ids + review_article_ids).uniq
    reported_comment_ids = Report.pending.where(reportable_type: 'Comment').pluck(:reportable_id)
    @actionable_articles = Article.with_discarded.where(id: all_article_ids)
                                  .includes(:user).order(updated_at: :desc).limit(5)
    @actionable_comments = Comment.with_discarded.where(id: reported_comment_ids)
                                  .includes(:user, :article).order(updated_at: :desc).limit(5)
    @actionable_items = (@actionable_articles + @actionable_comments)
                          .sort_by(&:updated_at).reverse.first(10)
    # Spotlight Section
    @most_clapped_articles = Article.order(claps_count: :desc).limit(3)
    @most_commented_articles = Article.order(comments_count: :desc).limit(3)
  end
end
