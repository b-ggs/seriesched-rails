require 'open-uri'
require 'nokogiri'
require 'uri'

class ApplicationController < ActionController::Base
  # Prevent CSRF attac\ks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def signup
    new_user = User.create_user(params[:username], params[:email], params[:password], params[:password2])
    session[:user_id] = new_user.id
    session[:username] = new_user.username
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
    @username = User.find(session[:user_id]).username
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
    @query = session[:search_query]
    @ids = session[:search_ids]
    @names = session[:search_names]
    @images = session[:search_images]

    if @query == nil
      @query = ""
    end
  end

  def search_action
    doc = xml_search(params[:searchquery])

    # ids = doc.xpath("//showid")
    # names = doc.xpath("//name")

    ids_arr =  data_array_from_doc_tag(doc, "showid")
    names_arr =  data_array_from_doc_tag(doc, "name")
    images_arr = images_from_id_array(ids_arr)

    session[:search_query] = params[:searchquery]
    session[:search_ids] = ids_arr[0, 10]
    session[:search_names] = names_arr[0, 10]
    session[:search_images] = images_arr[0, 10]

    redirect_to '/search'
  end

  def showdetails_init
    session[:showdetails_showid] = params[:showdetails_showid]

    redirect_to '/showdetails'
  end

  def showdetails
    showid = session[:showdetails_showid]

    doc = xml_full_show_info(showid)

    @show_name = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "name"))
    @show_image = get_show_image(showid)

    @show_showlink = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "showlink"))
    @show_started = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "started"))
    @show_ended = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "ended"))
    @show_origin_country = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "origin_country"))
    @show_status = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "status"))
    @show_classification = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "classification"))
    @show_genre = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "genre"))
    @show_runtime = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "runtime"))
    @show_airtime = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "airtime"))
    @show_airday = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "airday"))
    @show_timezone = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "timezone"))

    if @show_ended == "<ended/>"
      @show_ended = "Ongoing"
    end

    doc = xml_full_episode_list(showid)
    @total_season = data_array_from_doc_tag(doc, "totalseasons")
    @episode_snum = data_array_from_doc_tag(doc, "seasonnum")
    @episode_name = data_array_from_doc_tag(doc, "title")
  end

  def showdetails_action
  end

  # MISC FUNCTIONS

  def comma_delimited_string_from_array(a)
    string = ""

    for i in 0..a.length-1
      string += a[i]
      if i != a.length-1
        string += ", "
      end
    end

    string
  end

  def data_array_from_doc_tag(doc, tag)
    xpath = "//" + tag
    s = doc.xpath(xpath).to_s

    tagopen = "<" + tag + ">"
    tagclose = "</" + tag + ">"

    ret = s.split(tagopen).map{|x|x.split tagclose}.flatten.map(&:strip).reject(&:empty?)
    ret
  end

  def images_from_id_array(ids)
    images = []

    for i in 0..ids.length-1
      image = get_show_image(ids[i])
      images.push(image)
    end

    images
  end

  # EASY GETTERS

  def get_show_image(showid)
    doc = xml_full_show_info(showid)
    image_node = doc.xpath("//image").to_s
    image_arr = data_array_from_doc_tag(doc, "image")
    image = image_arr[0]
    image
  end

  # XML FUNCTIONS

  def xml_search(query)
    url = "http://services.tvrage.com/feeds/search.php?show=" + URI.escape(query) + ""
    doc = Nokogiri::XML(open(url).read)
    doc
  end

  def xml_full_show_info(showid)
    showid_str = URI.escape(showid.to_s) + ""
    url = "http://services.tvrage.com/feeds/full_show_info.php?sid=" +  showid_str + ""
    doc = Nokogiri::XML(open(url).read)
    doc
  end

  def xml_full_episode_list(showid)
    showid_str = URI.escape(showid.to_s) + ""
    url = "http://services.tvrage.com/feeds/episode_list.php?sid=" +  showid_str + ""
    doc = Nokogiri::XML(open(url).read)
    doc
  end
  
end
