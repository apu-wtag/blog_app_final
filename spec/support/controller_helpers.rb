module ControllerHelpers
  def sign_in(user)
    post login_path, params: { session: { login: user.email, password: user.password } }
  end
end
