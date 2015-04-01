class ApplicationController < ActionController::Base
  # Prevent CSRF attac\ks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def signup
  new_user = User.create_user(params[:username],params[:email],params[:password],params[:password2] )
  session[:user_id] = new_user.id
  redirect_to '/home'
  end

  def login
    user = User.authenticate(params[:username], params[:password])
    if user
      session[:user_id] = user.id
      redirect_to '/home'
    else
      redirect_to root_path
    end
  end

  def logout
    session[:user_id] = nil
    redirect_to root_path
  end
  
  def index
    if session[:user_id]
      redirect_to '/home'
    end
  end

  def home
  end

  def profile
  end

  def collection
  end

  def episodedetails
  end

  def schedule
  end

  def search
  end

  def showdetails
  end


  
end
