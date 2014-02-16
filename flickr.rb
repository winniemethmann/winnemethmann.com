class Flickr 
  include HTTParty

  API_KEY = ENV['FLICKRKEY']
  USER_ID = '28928462@N08'
  base_uri 'http://api.flickr.com'

  def self.photos(page = 1, per_page = 500)
    get("/services/rest/", :query => {
      :method => "flickr.people.getPublicPhotos",
      :api_key => API_KEY,
      :user_id => USER_ID,
      :extras => "date_upload",
      :per_page => per_page,
      :page=> page,
     })
  end

  def self.photo(id)
    get("/services/rest/", :query => {
      :method => "flickr.photos.getInfo",
      :api_key => API_KEY,
      :photo_id => id,
    })
  end

  def self.context(id)
    get("/services/rest/", :query => {
      :method => "flickr.photos.getContext",
      :api_key => API_KEY,
      :photo_id => id,
    })
  end
end
