require 'sinatra'
require 'slim'
require 'haml'

require 'json'

require 'pry'

require_relative 'lib/psd/psd_parser'

class App < Sinatra::Base

# Handle GET-request (Show the upload form)
  get '/upload' do
    haml :upload, layout: :layout
  end

# Handle POST-request (Receive and save the uploaded file)
  post '/upload' do
    File.open('uploads/' + params['myfile'][:filename], "w") do |f|
      f.write(params['myfile'][:tempfile].read)
    end
    redirect_url = '/process/' + params['myfile'][:filename].chomp('.psd')
    redirect redirect_url
  end

  get '/process/:name' do
    render_html_psd  PsdParser.new("./uploads/#{params[:name]}.psd").parse(:hash)
  end

  get '/slim_example' do
    slim :slim_example
  end

  get '/hello_world_json' do
    content_type 'application/json'
    PsdParser.new('./psds/hello_world.psd').parse :json
  end

  get '/hello_world_alt_json' do
    content_type 'application/json'
    PsdParser.new('./psds/hello_world_alternative_font.psd').parse :json
  end

  get '/hello_world_html' do
    contents = PsdParser.new('./psds/hello_world.psd').parse :hash
    render_html_psd contents
  end

  private

  def render_html_psd(contents)

    text_node = contents.children[0][:text]

    text = text_node[:value]
    style = text_node[:font][:css]
    font_size = text_node[:font][:sizes][0]
    font_name = text_node[:font][:name]

    font_family = style.split(';').find do |css_directive|
      css_directive =~ /font-family\:/
    end.gsub(/font-family\:/, '')

    corrected_font_family = font_family
    if font_name == 'AdobeInvisFont'
      corrected_font_family = font_family.split(',').last
    end

    style = style.split(';').select do |css_directive|
      not (css_directive =~ /font-family\:/ or css_directive =~ /font-size\:/)
    end.push('font-family: ' + corrected_font_family)
       .push("font-size: #{font_size}px") 
       .join(';')

    page_style = generate_page_style contents

    slim :hello_world, {locals: {text: text, style: style, page_style: page_style }}
  end


  def generate_page_style(contents)
    height = contents.document.width
    width = contents.document.height

    "height:#{height}px; width:#{width}px;border:1px solid black;"
  end

end