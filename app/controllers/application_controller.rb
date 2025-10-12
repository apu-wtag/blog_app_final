class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user
  include Pundit::Authorization
  include Pagy::Backend
  before_action :set_locale
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
  def default_url_options
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
  end
  private
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def current_user
    # return @current_user if defined?(@current_user)

    if session[:user_id]
      user = User.find_by(id: session[:user_id])
      if user&.kept? && session[:session_token] == user.session_token
        @current_user ||= user
      else
        log_out_user
        @current_user = nil
      end
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user&.kept? && user.authenticated?("remember", cookies.signed[:remember_token])
        reset_session
        user.regenerate_session_token
        session[:session_token] = user.session_token
        session[:user_id] = user.id
        @current_user = user
      else
        log_out_user
        @current_user = nil
      end
    end
  end

  def log_out_user
    # reset_session
    session.delete(:user_id)
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def require_login
    unless current_user
      redirect_to login_path , alert: "You must be logged in to access this page."
    end
  end

  def require_no_login
    if current_user
      redirect_to root_path, notice: "You are already logged in."
    end
  end
  def log_in(user)
    reset_session
    user.regenerate_session_token
    session[:session_token] = user.session_token
    session[:user_id] = user.id
  end
  def log_out
    forget(current_user) if current_user
    reset_session
    @current_user = nil
  end

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = {
      value: user.id,
      expires: 30.days.from_now,
      secure: true,
      http_only: true,
      same_site: :lax
    }
    cookies.permanent.signed[:remember_token] = {
      value: user.remember_token,
      expires: 30.days.from_now,
      secure: true,
      http_only: true,
      same_site: :lax
    }
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
  def record_not_found(exception)
    redirect_to root_path, notice: "#{exception.message} not found"
  end

end