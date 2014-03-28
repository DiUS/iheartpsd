require 'sinatra'
require 'slim'
require 'haml'

require 'json'

require 'pry'

require 'recursive-open-struct'

require_relative 'lib/psd/psd_parser'

class App < Sinatra::Base

  @@file_name = 'box'

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
    raw_contents = PsdParser.new("./uploads/#{params[:name]}.psd").parse(:plain).tree
    contents = RecursiveOpenStruct.new(raw_contents.to_hash)
    render_html_psd contents, raw_contents
  end

  get '/slim_example' do
    slim :slim_example
  end

  get '/example_json' do
    content_type 'application/json'
    PsdParser.new("./psds/#{@@file_name}.psd").parse :json
  end

  get '/example_html' do
    contents = PsdParser.new("./psds/#{@@file_name}.psd").parse :hash
    render_html_psd contents
  end

  get '/example_json' do
    content_type 'application/json'
    PsdParser.new('./psds/hello_world.psd').parse :json
  end

  get '/hello_world_alt_json' do
    content_type 'application/json'
    PsdParser.new('./psds/hello_world_alternative_font.psd').parse :json
  end

  get '/hello_world_multi' do
    content_type 'application/json'
    PsdParser.new('./psds/image.psd').parse :json
  end

  get '/image_raw_ouput' do
    psd = PsdParser.new('./psds/image.psd').parse(:plain)
    content_type 'text/plain'
    "#{psd.layer_comps}"
  end

  get '/image_html' do
    raw_contents = PsdParser.new('./psds/image.psd').parse(:plain).tree
    contents = RecursiveOpenStruct.new(raw_contents.to_hash)
    render_html_psd contents, raw_contents
  end

  get '/hello_world_html' do
    raw_contents = PsdParser.new('./psds/hello_world_multi_styles.psd').parse(:plain).tree
    contents = RecursiveOpenStruct.new(raw_contents.to_hash)
    render_html_psd contents, raw_contents
  end

  private

  def render_html_psd(contents, raw_contents)
    page_style = generate_page_style contents

    layer_nodes = contents.children.select do |child|
      child[:type] == :layer and child[:name] != 'Background'
    end

    text_layer_nodes = layer_nodes.select do |layer_node|
      layer_node[:text]
    end

    text_layers = text_layer_nodes.map do |layer_node|

      layer_hash = {}
      layer_hash.merge!({text: generate_text_element(layer_node)}) if layer_node[:text]
      layer_hash.merge!({box: generate_box_element(layer_node)}) if(layer_node[:name] =~ /Rectangle.*/)

      layer_style_hash = {left: layer_node[:left], top: layer_node[:top]}
      layer_style = layer_style_hash.to_a.map do |position_statement|
        "#{position_statement[0]}: #{position_statement[1]}px"
      end.join(';')

      layer_hash.merge!({style: layer_style})

      RecursiveOpenStruct.new(layer_hash)
    end

    image_layer_nodes = raw_contents.descendant_layers.select do |layer_node|
      layer_node.name =~ /IMG_/
    end

    image_layers = image_layer_nodes.map do |image_layer|
      image_layer.save_as_png "./public/tmp/#{image_layer.name}.png"

      layer = {
        left: image_layer.left,
        top: image_layer.top,
      }
      layer_style = layer.to_a.map do |position_statement|
        "#{position_statement[0]}: #{position_statement[1]}px" 
      end.join(';')

      RecursiveOpenStruct.new({
        style: layer_style,
        image_src: "/tmp/#{image_layer.name}.png"
      })
    end

    slim :hello_world, {locals: {text_layers: text_layers, image_layers: image_layers, page_style: page_style }}
  end

  def generate_page_style(contents)
    "height:#{contents.document.width}px; width:#{contents.document.height}px;border:1px solid black;"
  end

  def generate_text_element(layer_node)

    text_node = layer_node[:text]

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

    tooltip = style.gsub(/;/, ';<br>')
    puts tooltip
    
    {text: text, style: style, tooltip: tooltip }
  end

  def generate_box_element(layer_node)

    box_style_hash = {
      left: layer_node[:left],
      right: layer_node[:right],
      top: layer_node[:top],
      bottom: layer_node[:bottom]
    }


    layer_style = generate_style_from_hash(box_style_hash) + ';background: grey;'

    {style:layer_style}
  end

  def generate_style_from_hash(hash)
    hash.to_a.map do |position_statement|
      "#{position_statement[0]}: #{position_statement[1]}px"
    end.join(';')
  end

end