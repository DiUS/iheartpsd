require 'psd'
require 'recursive-open-struct'

class PsdParser

  def initialize(file_path)
    psd_path = File.expand_path file_path
    @psd = PSD.new psd_path
  end

  def parse(type = :hash)
    @psd.parse!
    return RecursiveOpenStruct.new(@psd.tree.to_hash)if type == :hash
    return @psd.tree.to_hash.to_json if type == :json
  end
end