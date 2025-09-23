class ResetMailerJob
  include Sidekiq::Job

  def perform(user_id,token)
    user = User.find(user_id)
    UserMailer.password_reset(user,token).deliver_now
  end
end
