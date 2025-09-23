class AuthorNotifierJob
  include Sidekiq::Job

  def perform(moderation_record_id, action)
    record = ModerationRecord.find_by(id: moderation_record_id)
    return unless record
    case action.to_s
    when "hidden"
      AuthorNotificationMailer.article_hidden(record).deliver_now
    when "approved"
      AuthorNotificationMailer.request_approved(record).deliver_now
    when "rejected"
      AuthorNotificationMailer.request_rejected(record).deliver_now
    end
  end
end
