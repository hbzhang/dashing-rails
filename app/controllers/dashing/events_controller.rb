module Dashing
  class EventsController < ApplicationController
    include ActionController::Live

    def index
      response.headers['Content-Type']      = 'text/event-stream'
      response.headers['X-Accel-Buffering'] = 'no'

      @redis = Dashing.redis
      @redis.psubscribe("#{Dashing.config.redis_namespace}.*") do |on|
        on.pmessage do |pattern, event, data|
          #logger.info "data: #{data}\n\n"
          response.stream.write("data: #{data}\n\n")
        end
      end
      @redis.flushdb
      @redis.shutdown { |conn| conn.close }
    rescue IOError
      logger.info "[Dashing][#{Time.now.utc.to_s}] Stream closed"
    ensure
      #@redis.quit
      response.stream.close
    end

  end
end
