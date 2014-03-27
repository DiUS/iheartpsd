require 'sinatra'
require 'slim'
require 'psd'
require 'json'

class App < Sinatra::Base

  get '/upload' do
     :upload
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