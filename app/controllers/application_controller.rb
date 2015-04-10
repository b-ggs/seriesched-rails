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
    session[:username] = nil
    session[:search_query] = nil
    session[:search_ids] = nil
    session[:search_names] = nil
    session[:search_images] = nil
    session[:episodedetails_showid] = nil
    session[:episodedetails_season] = nil
    session[:episodedetails_episode] = nil

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
    doc = txt_quickchedule()

    @temp = ""

    schedule_raw = parse_quickschedule(doc)
    @schedule = []

    current_day = nil
    current_time = nil

    schedule_days = nil
    schedule_item = nil

    for i in 0..schedule_raw.length-1
      s = schedule_raw[i]

      if s == "DAY"
        # current_day = schedule_raw[i+1]
        if schedule_days != nil
          @schedule.push(schedule_days)
        end
        schedule_days = Hash.new(nil)
        schedule_days["day"] = schedule_raw[i+1]
        schedule_days["data"] = []
      elsif s == "TIME"
        current_time = schedule_raw[i+1]
      elsif s == "SHOW"
        show_raw = schedule_raw[i+1].split("^").each_slice(1).map{|a| a.join ' '}.flatten.map(&:strip).reject(&:empty?)

        show_network = show_raw[0]
        show_name = show_raw[1]
        show_season_episode = show_raw[2].split("x").each_slice(1).map{|a| a.join ' '}.flatten.map(&:strip).reject(&:empty?)
        show_season = show_season_episode[0]
        show_episode = show_season_episode[1]
        show_url = show_raw[3]

        if show_season.to_i.to_s != "0"
          show_season = show_season.to_i.to_s
        end

        if show_episode.to_i.to_s != "0"
          show_episode = show_episode.to_i.to_s
        end

        schedule_item = Hash.new(nil)
        schedule_item["time"] = current_time
        schedule_item["network"] = show_network
        schedule_item["name"] = show_name
        schedule_item["season"] = show_season
        schedule_item["episode"] = show_episode
        schedule_item["url"] = show_url
        # schedule_item["sid"] = get_show_id(show_name)

        # schedule.push(schedule_item)
        schedule_days["data"].push(schedule_item)
      end
    end

    if schedule_days != nil
      @schedule.push(schedule_days)
    end
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

    showname = params[:showname]

    if showid.present?
      if episode.length == 1
        episode = "0" + episode
      end
    elsif showname.present?
      showid = get_show_id(showname)
      if episode.length == 1
        episode = "0" + episode
      end
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
    @username = User.find(session[:user_id]).username
    ids_collection = Collection.where(username:@username).all.to_a
    urls_collection = []

    for i in 0..ids_collection.length-1
      urls_collection.push(ids_collection[i].url)
    end

    @collection_length = urls_collection.length

    doc = txt_quickchedule()

    schedule_raw = parse_quickschedule(doc)
    @schedule = []
    @schedule_length = 0

    current_day = nil
    current_time = nil

    schedule_days = nil
    schedule_item = nil

    for i in 0..schedule_raw.length-1
      s = schedule_raw[i]

      if s == "DAY"
        # current_day = schedule_raw[i+1]
        if schedule_days != nil
          @schedule.push(schedule_days)
        end
        schedule_days = Hash.new(nil)
        schedule_days["day"] = schedule_raw[i+1]
        schedule_days["data"] = []
      elsif s == "TIME"
        current_time = schedule_raw[i+1]
      elsif s == "SHOW"
        show_raw = schedule_raw[i+1].split("^").each_slice(1).map{|a| a.join ' '}.flatten.map(&:strip).reject(&:empty?)

        show_network = show_raw[0]
        show_name = show_raw[1]
        show_season_episode = show_raw[2].split("x").each_slice(1).map{|a| a.join ' '}.flatten.map(&:strip).reject(&:empty?)
        show_season = show_season_episode[0]
        show_episode = show_season_episode[1]
        show_url = show_raw[3]
        if show_url.present?
          show_url = show_url.split("www.").join()
        end

        if show_season.to_i.to_s != "0"
          show_season = show_season.to_i.to_s
        end

        if show_episode.to_i.to_s != "0"
          show_episode = show_episode.to_i.to_s
        end

        schedule_item = Hash.new(nil)
        schedule_item["time"] = current_time
        schedule_item["network"] = show_network
        schedule_item["name"] = show_name
        schedule_item["season"] = show_season
        schedule_item["episode"] = show_episode
        schedule_item["url"] = show_url
        
        contains_flag = false

        for j in 0..urls_collection.length-1
          curr_url = urls_collection[j].to_s
          if show_url.present?
            if show_url.downcase.gsub('-', '_') == curr_url.downcase.gsub('-', '_')
              contains_flag = true
            end
          end
        end

        if contains_flag == true
          schedule_days["data"].push(schedule_item)
          @schedule_length = @schedule_length + 1
        end
      end
    end

    if schedule_days != nil 
      @schedule.push(schedule_days)
    end
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
    showid = params[:showdetails_showid]
    showname = params[:showname]

    if showid.present?
      session[:showdetails_showid] = showid
    elsif showname.present?
      session[:showdetails_showid] = get_show_id(showname)
    end

    redirect_to '/showdetails'
  end

  def showdetails
    @showid = session[:showdetails_showid]

    @is_in_collection = is_in_collection(@showid)

    doc = xml_full_show_info(@showid)

    @show_name = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "name"))
    @show_image = get_show_image(@showid)

    @show_showlink = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "showlink").uniq.sort)
    @show_started = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "started").uniq.sort)
    @show_ended = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "ended").uniq.sort)
    @show_origin_country = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "origin_country").uniq.sort)
    @show_status = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "status").uniq.sort)
    @show_classification = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "classification").uniq.sort)
    @show_genre = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "genre").uniq.sort)
    @show_runtime = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "runtime").uniq.sort)
    @show_airtime = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "airtime").uniq.sort)
    @show_airday = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "airday").uniq.sort)
    @show_timezone = comma_delimited_string_from_array(data_array_from_doc_tag(doc, "timezone").uniq.sort)

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
    url = params[:showdetails_url]

    Collection.create(username:username, showid:showid, url:url)

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

  def parse_quickschedule(doc)
    s = doc.to_s

    ret = s.split('[').map{|x|x.split ']'}.flatten.map(&:strip).reject(&:empty?)
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

  def get_show_id(showname)
    sid = 1
    doc = txt_quickinfo(showname)
    s = doc.to_s
    sid_raw = s.split(' ').map{|x|x.split '@'}.flatten.map(&:strip).reject(&:empty?)
    sid_raw[2]
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

  def txt_quickinfo(showname)
    url = "http://services.tvrage.com/tools/quickinfo.php?show=" + URI.escape(showname) + "&exact=1"
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