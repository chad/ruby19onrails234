Dir.glob((Rails.root + 'lib/*_ext/*.rb').to_s).each do |file|
  require file
end
