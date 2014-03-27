require 'sinatra'
require 'slim'
require 'psd'
require 'json'

class App < Sinatra::Base

  get '/upload' do
     haml :upload
  end

  post '/upload' do
    unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
      return haml(:upload)
    end
  end

  get '/slim_example' do
    slim :slim_example
  end

  get '/hello_world' do
    psd_path = File.expand_path '../psds/hello_world.psd', __FILE__
    psd = PSD.new psd_path
    psd.parse!

    content_type 'application/json'
    psd.tree.to_hash.to_json
  end

end