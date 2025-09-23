class AuthorNotificationMailer < ApplicationMailer
  def article_hidden(record)
    send_notification(record, "An update on your article: #{record.article.title}")
  end
  def request_approved(record)
    send_notification(record, "Your article has been restored!")
  end
  def request_rejected(record)
    send_notification(record, "An update on your article restoration request")
  end
  private
  def send_notification(record, subject)
    @record  = record
    @article = record.article
    @user    = @article.user
    mail(to: @user.email, subject: subject)
  end
end
