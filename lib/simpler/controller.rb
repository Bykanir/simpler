require_relative 'view'

module Simpler
  class Controller

    attr_reader :name, :request, :response

    def initialize(env)
      @name = extract_name
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
    end

    def make_response(action, logger)
      @request.env['simpler.controller'] = self
      @request.env['simpler.action'] = action

      set_params
      log_request(logger)
      send(action)
      set_headers
      set_status
      write_response
      log_response(logger)

      @response.finish
    end

    private

    def extract_name
      self.class.name.match('(?<name>.+)Controller')[:name].downcase
    end

    def set_headers
      if @request.env['simpler.template'].class == Hash
        set_response_headers
      else
        set_default_headers
      end
    end

    def set_response_headers
      if @request.env['simpler.template'].keys.first == :plain
        @response['Content-Type'] = 'text/plain'
      end
    end

    def set_status
      return unless @request.env['simpler.template'].class == Hash

      if @request.env['simpler.template'].keys.include?(:status)
        @response.status = @request.env['simpler.template'][:status]
      end
    end

    def set_default_headers
      @response['Content-Type'] = 'text/html'
    end

    def write_response
      body = render_body

      @response.write(body)
    end

    def render_body
      if @request.env['simpler.template'].class == Hash
        render_format
      else
        View.new(@request.env).render(binding)
      end
    end

    def set_params
      if @request.env['simpler.action'] == 'show'
        @request.params['id'] = @request.env['REQUEST_PATH'].gsub(/\D+/, '')
      end
    end

    def params
      @request.params
    end

    def render(template)
      @request.env['simpler.template'] = template
    end

    def render_format
      format = @request.env['simpler.template'].keys.first
      text = @request.env['simpler.template'].values.first
      case format
      when :json
        format_json(text)
      when :xml
        format_xml(text)
      when :plain
        format_plain(text)
      end
    end

    def format_json(text)
      json = 'json'
      type_definition(json)
      text
    end

    def format_xml(text)
      xml = 'xml'
      type_definition(xml)
      text
    end

    def format_plain(text)
      plain = 'plain'
      type_definition(plain)
      text
    end

    def type_definition(type) 
      @response['Content-Type'] = "text/#{type}"
    end

    def log_request(logger)
      logger.info("Handler: #{@request.env['simpler.controller'].class}##{@request.env['simpler.action']}\nParameters: #{params}" )
    end

    def log_response(logger)
      logger.info("Response: #{@response.status} [#{@response['Content-Type']}] #{@request.env['simpler.template'] || [extract_name, @request.env['simpler.action']].join('/') + '.html.erb'}")
    end
    
  end
end
