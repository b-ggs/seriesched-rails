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
    if session[:user_id] != nil
      redirect_to '/home'
    end
  end

  def home
    if session[:user_id] == nil
      redirect_to root_path
    else
      @username = User.find(session[:user_id]).username
    end
  end

  def profile
  end

  def browse
    doc = xml_full_schedule()

    @temp = doc.xpath("//schedule//DAY").to_s
  end

  def recent
  end

  def collection
    @username = User.find(session[:user_id]).username
    ids_collection = Collection.where(username:@username).all.to_a

    @ids = []

    for i in 0..ids_collection.length-1
      @ids.push(ids_collection[i].showid)
    end

    @names = names_from_id_array(@ids)
    @images = images_from_id_array(@ids)
  end

  def episodedetails_init
    showid = params[:showid]
    season = params[:season]
    episode = params[:episode]

    if episode.length == 1
      episode = "0" + episode
    end

    session[:episodedetails_showid] = showid
    session[:episodedetails_season] = season
    session[:episodedetails_episode] = episode

    redirect_to '/episodedetails'
  end

  def episodedetails
    @showid = session[:episodedetails_showid].to_s
    @season = session[:episodedetails_season].to_s
    @episode = session[:episodedetails_episode].to_s

    sxep = @season + "x" + @episode
    doc = xml_episode_details(@showid, sxep)

    @episode_title = comma_delimited_string_from_array(data_array_from_doc_xpath_tag(doc, "//episode//title", "title"))
    @show_name = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "name"))
    @show_runtime = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "runtime"))
    @show_airdate = comma_delimited_string_from_array(data_array_from_doc_xpath_tag(doc, "//episode//airdate", "airdate"))
    @show_url = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "url"))
  end

  def schedule
    doc = txt_quickchedule()

    @temp = doc.to_s

    # doc = xml_full_schedule()

    # @temp = data_array_from_doc_end_tag(doc, "//schedule//DAY", "DAY")

    # @temp = data_array_from_doc_end_tag(doc, "//schedule//DAY", "DAY").first
    # @attr = get_attr_value(@temp, "DAY")

    # schedule = {}

    # days_array = data_array_from_doc_end_tag(doc, "//schedule//DAY", "DAY")

    # for i in 0..days_array.length-1
    #   schedule[days_array[i]] = {}
    #   times_array = data_array_from_doc_end_tag(doc, "//schedule//DAY//time", "time")
    #   for j in 0..times_array.length-1
    #     schedule[days_array[i]][times_array[j]] = {}
    #   end
    # end

    # schedule_keys = schedule.keys

    # @temp = days_array
  end

  def search_init
    session[:search_query] = nil
    session[:search_ids] = nil
    session[:search_names] = nil
    session[:search_images] = nil

    redirect_to "/search"
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
    @showid = session[:showdetails_showid]

    @is_in_collection = is_in_collection(@showid)

    doc = xml_full_show_info(@showid)

    @show_name = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "name"))
    @show_image = get_show_image(@showid)

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

    doc = xml_full_episode_list(@showid)
    @total_season = data_array_from_doc_tag(doc, "totalseasons")
    @episode_snum = data_array_from_doc_tag(doc, "seasonnum")
    @episode_name = data_array_from_doc_tag(doc, "title")

    @season = Array.new 
    count = -1;
    for i in 0..(@episode_snum.length-1)
      if @episode_snum[i] == "01"
        count = count + 1
        @season[count] = Array.new
      end
       @season[count].push(@episode_name[i])
    end
  end

  def showdetails_add
    username = User.find(session[:user_id]).username
    showid = params[:showdetails_showid]

    Collection.create(username:username, showid:showid)

    session[:showdetails_showid] = showid

    redirect_to "/showdetails"
  end

  def showdetails_remove
    username = User.find(session[:user_id]).username
    showid = params[:showdetails_showid]

    Collection.where(username:username, showid:showid).first.destroy

    session[:showdetails_showid] = showid

    redirect_to "/showdetails"
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

  def is_in_collection(showid)
    username = User.find(session[:user_id]).username
    set = Collection.where(username:username, showid:showid)
    if set.length > 0
      true
    else
      false
    end
  end

  def images_from_id_array(ids)
    images = []

    for i in 0..ids.length-1
      image = get_show_image(ids[i])
      images.push(image)
    end

    images
  end

  def names_from_id_array(ids)
    names = []

    for i in 0..ids.length-1
      name = get_show_name(ids[i])
      names.push(name)
    end

    names
  end

  # DOC FUNCTIONS

  def data_array_from_doc_tag(doc, tag)
    xpath = "//" + tag
    s = doc.xpath(xpath).to_s

    tagopen = "<" + tag + ">"
    tagclose = "</" + tag + ">"

    ret = s.split(tagopen).map{|x|x.split tagclose}.flatten.map(&:strip).reject(&:empty?)
    ret
  end

  def data_array_from_doc_xpath_tag(doc, xpath, tag)
    s = doc.xpath(xpath).to_s

    tagopen = "<" + tag + ">"
    tagclose = "</" + tag + ">"

    ret = s.split(tagopen).map{|x|x.split tagclose}.flatten.map(&:strip).reject(&:empty?)
    ret
  end

  # def data_array_from_doc_end_tag(doc, xpath, tag)
  #   s = doc.xpath(xpath).to_s

  #   tagclose = "</" + tag + ">"

  #   ret = s.split(tagclose).each_slice(1).map{|a| a.join ' '}.flatten.map(&:strip).reject(&:empty?)
  #   ret
  # end

  # EASY GETTERS

  def get_show_name(showid)
    doc = xml_full_show_info(showid)
    name_node = doc.xpath("//name").to_s
    name_arr = data_array_from_doc_tag(doc, "name")
    name = name_arr[0]
    name
  end

  def get_show_image(showid)
    doc = xml_full_show_info(showid)
    image_node = doc.xpath("//image").to_s
    image_arr = data_array_from_doc_tag(doc, "image")
    image = image_arr[0]
    image
  end

  # TEXT FUNCTIONS

  def txt_quickchedule
    url = "http://services.tvrage.com/tools/quickschedule.php"
    doc = open(url).read { |f| f.read }
    doc
  end

  # XML FUNCTIONS

  def xml_search(query)
    url = "http://services.tvrage.com/feeds/search.php?show=" + URI.escape(query) + ""
    doc = Nokogiri::XML(open(url).read)
    doc
  end

  def xml_full_show_info(showid)
    # showid_str = URI.escape(showid.to_s) + ""
    showid_str = showid.to_s + ""
    url = "http://services.tvrage.com/feeds/full_show_info.php?sid=" +  showid_str + ""
    doc = Nokogiri::XML(open(url).read)
    doc
  end

  def xml_full_episode_list(showid)
    # showid_str = URI.escape(showid.to_s) + ""
    showid_str = showid.to_s + ""
    url = "http://services.tvrage.com/feeds/episode_list.php?sid=" +  showid_str + ""
    doc = Nokogiri::XML(open(url).read)
    doc
  end

  def xml_episode_details(showid, ep)
    # showid_str = URI.escape(showid.to_s) + ""
    showid_str = showid.to_s + ""
    url = "http://services.tvrage.com/feeds/episodeinfo.php?sid=" +  showid_str + "&ep=" + ep + ""
    doc = Nokogiri::XML(open(url).read)
    doc
  end

  def xml_full_schedule
    url = "http://services.tvrage.com/feeds/fullschedule.php?country=US&24_format=1"
    doc = Nokogiri::XML(open(url).read)
    doc
  end
  
end
