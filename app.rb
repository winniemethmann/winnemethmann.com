require 'rubygems'
require 'bundler'
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require './flickr.rb'

configure do
  set :public_folder, Proc.new { File.join(root, "public") }
  set :sessions, false
  set :logging, true
end

helpers do
  def get_photos
    Flickr.photos['rsp']['photos']['photo']
  end

  def get_photo(id)
    Flickr.photo(id)['rsp']['photo']
  end

  def get_context(id)
    Flickr.context(id)['rsp']
  end

  def photo_url(photo, size = "")
    url = "http://farm%s.static.flickr.com/%s/%s_%s%s.jpg"
    size = "_" + size unless size.empty?
    url % [photo['farm'], photo['server'], photo['id'], photo['secret'], size]
  end

  def photo_page_url(photo)
    '/' + photo['id'] + '/' + photo['title'].gsub(/ /, '-')
  end

  def convert_line_breaks(text)
    if text != nil
      text.strip!
      text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
      text.gsub!(/\n\n+/, "</p>\n\n<p>")           # 2+ newline  -> paragraph
      text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
      text.insert 0, "<p>"
      text << "</p>"
    end
  end
end

get '/' do
  cache_control :public, max_age: 7200 # two hours
  @pieces = get_photos
  haml :index
end

get '/:id/:title' do
  cache_control :public, max_age: 172800 # two days
  @photo = get_photo(params[:id])
  @context = get_context(params[:id])
  raise Sinatra::NotFound if @photo == nil
  haml :photo
end

get '/custom.css' do
  cache_control :public, max_age: 7200 # two hours
  content_type 'text/css'
  sass :customcss
end

get '/sitemap.xml' do
  cache_control :public, max_age: 7200 # two hours
  @pieces = get_photos

  map = XmlSitemap::Map.new('www.winniemethmann.com') do |m|
    @pieces.each do |piece|
      m.add(photo_page_url(piece), :updated => Time.at(piece["dateupload"].to_i))
    end
  end

  headers['Content-Type'] = 'text/xml'
  map.render
end


not_found do
  haml :not_found
end

__END__

@@ layout
!!! 5
%html
  %head
    %title
      = yield_content :title
      | Winnie Methmann Photography
    %meta{:content => "width=device-width, initial-scale=1.0", :name => "viewport"}
    %meta{:content => "Winnie Methmann is a Danish fashion and design photographer", :name => "description"}
    %meta{:content => "Winnie Methmann", :name => "author"}
    - unless yield_content(:image_src).empty?
      %link{:rel => "image_src", :href => yield_content(:image_src)}
    %link{:rel => "stylesheet", :href => "/css/bootstrap.min.css", :type => "text/css"}
    %link{:rel => "stylesheet", :href => "/custom.css", :type => "text/css"}
    %link{:rel => "stylesheet", :href => "/css/jquery.justifiedgallery.css", :type => "text/css"}
    %link{:rel => "stylesheet", :href => "/css/colorbox.css", :type => "text/css"}
    %script{:src => "//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js", :type => "text/javascript"}
    %script{:src => "/js/jquery.justifiedgallery.js", :type => "text/javascript"}
    %script{:src => "/js/jquery.colorbox-min.js", :type => "text/javascript"}
  %body{:class => yield_content(:body_class) }
    %div{:class => "container-narrow"}
      %div{:class => "masthead"}
        %h1
          %a{:href => "/"}
            %img{:src => "/img/logo.png"}
      %div{:class => "container-fluid"}
        = yield
      #footer
        %p a Danish fashion and design photographer
        &copy;
        %a{:href => "http://www.winniemethmann.com/"} Winnie Methmann
        = Time.now.year
        = haml :ga


@@ index
- content_for :title do
  Home
- content_for :body_class do
  index
#container
  - @pieces.each do |piece|
    %a{:href => photo_url(piece, 'b'), :title => piece['title']}
      %img{:src => photo_url(piece, 'm'), :alt => piece['title']}
  :javascript
    $("#container").justifiedGallery({
      'onComplete': function(gal) {
        $(gal).find("a").colorbox({
          maxWidth : "80%",
          maxHeight : "80%",
          opacity : 0.8,
          transition : "elastic",
          current : ""
        });
      }
    });

@@ photo
- content_for :title do
  = @photo['title']
- content_for :image_src do
  = photo_url(@photo, "o")
- content_for :body_class do
  photo
%piece
  %h4
    = @photo['title']
  %div{:class => "row"}
    %div{:class => "span8"}
      %img{:src => photo_url(@photo, "z")}
    %div{:class => "span3"}
      = (@photo['tags']['tag'].map { |tag| tag['__content__'].downcase } | @photo['tags']['tag'].map { |tag| tag['raw'].downcase }).sort.join ", " unless @photo['tags'] == nil

@@ga
:javascript
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
  ga('create', 'UA-120957-14', 'winniemethmann.com');
  ga('send', 'pageview');

@@ not_found
- content_for :title do
  Not found (404)
%h4 Not found

@@ customcss
body
  padding-top: 20px
  padding-bottom: 40px
  background-color: #222
  color: #ccc
  font-size: 12px

.masthead
  margin: 20px
  margin-bottom: 40px

.container-fluid
  margin: 0px

#footer
  padding-top: 20px
  font-size: 16px
  line-height: 40px
  clear: both
  text-align: center
  a
    text-decoration: underline
    color: #ccc

h1 a
  color: #ccc
  &:hover
    text-decoration: none
    color: #ccc
p
  line-height: 1.3em
  margin-bottom: .5em

h1
  line-height: 10px
  letter-spacing: 13px
  text-transform: uppercase

h3
  margin-top: 0px
  margin-bottom: 30px
