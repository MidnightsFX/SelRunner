require 'logger'
require 'celluloid/current'
require 'celluloid/io'

# Loggind module, using a shared module class
module Log
  include Celluloid

  # msg, level (E-rror,W-arn,I-nfo,D-ebug)
  def self.write(msg, level)
    #log = Logger.new(file, 'daily')
    log = Logger.new(STDOUT)
  
    # If you want some info, you should change this level, and run it
    log.level = Logger::INFO # DEBUG, INFO, WARN, ERROR
    begin
      case level
      when :E
        log.error { msg }
      when :W
        log.warn { msg }
      when :I
        log.info { msg }
      when :D
        log.debug { msg }
      end

    rescue => e
      log.fatal { 'Logging Error: ' + e }
    end
  end # end logging
end # end Log
