class BillyClient
  include HTTParty
  format :json
  base_uri 'https://api.billysbilling.com/v2/'
  headers 'X-Access-Token' => Rails.application.secrets.billy[:api_key]
  headers 'Content-Type' => 'application/json'

  def self.show(name, id)
    res = get "/#{name.pluralize}/#{id}"
    res[name]
  end

  def self.create(name, params)
    url = "/#{name.pluralize}"
    Log.note "Billy is about to POST to #{url} with params: #{params}"
    return_with post(url, body: {name => params}.to_json), name
  end

  def self.update(name, id, params)
    url = "/#{name.pluralize}/#{id}"
    Log.note "Billy is about to PUT to #{url} with params: #{params}"
    return_with put(url, body: {name => params}.to_json), name
  end

  def self.index(name)
    res = get "/#{name.pluralize}"
    return res
    res[name.pluralize]
  end

  def self.return_with(res, name)
    if res.success?
      res[name.pluralize].first
    else
      Log.error_and_notify "Billy could not return resource: #{res}"
      # Log.fatal "Billy could not return resource: #{res}"
    end
  end
end
