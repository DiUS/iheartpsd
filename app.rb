require 'sinatra'
require 'slim'

class App < Sinatra::Base

  get '/upload' do
     :upload
  end

  get '/slim_example' do
    slim :slim_example
  end

end