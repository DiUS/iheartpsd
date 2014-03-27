require 'sinatra'
require 'slim'
require 'haml'
require 'psd'
require 'json'
require 'recursive-open-struct'

require 'pry'

class App < Sinatra::Base

# Handle GET-request (Show the upload form)
  get '/upload' do
    haml :upload
  end

# Handle POST-request (Receive and save the uploaded file)
  post '/upload' do
    File.open('uploads/' + params['myfile'][:filename], "w") do |f|
      f.write(params['myfile'][:tempfile].read)
    end
    redirect '/process/' + /myfile
  end


  get '/slim_example' do
    slim :slim_example
  end

  get '/hello_world_json' do
    psd_path = File.expand_path '../psds/hello_world.psd', __FILE__
    psd = PSD.new psd_path
    psd.parse!

    content_type 'application/json'
    psd.tree.to_hash.to_json
  end

  get '/hello_world_html' do
    psd_path = File.expand_path '../psds/hello_world.psd', __FILE__
    psd = PSD.new psd_path
    psd.parse!

    contents = RecursiveOpenStruct.new psd.tree.to_hash

    text_node = contents.children[0][:text]

    text = text_node[:value]
    style = text_node[:font][:css]

    slim :hello_world, {locals: {text: text, style: style}}
  end

end