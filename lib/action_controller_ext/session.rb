module ActionController
  module Integration
    class Session
      # Performs the actual request.
      def process(method, path, parameters = nil, headers = nil)
        data = requestify(parameters)
        path = interpret_uri(path) if path =~ %r{://}
        path = "/#{path}" unless path[0] == ?/
        @path = path
        env = {}

        if method == :get
          env["QUERY_STRING"] = data
          data = nil
        end

        env["QUERY_STRING"] ||= ""

        data = data.is_a?(IO) ? data : StringIO.new(data || '')

         # rack requires binary encoded rack.input
        data.set_encoding(Encoding::ASCII_8BIT) if data.respond_to?(:set_encoding)
        env.update(
          "REQUEST_METHOD"  => method.to_s.upcase,
          "SERVER_NAME"     => host,
          "SERVER_PORT"     => (https? ? "443" : "80"),
          "HTTPS"           => https? ? "on" : "off",
          "rack.url_scheme" => https? ? "https" : "http",
          "SCRIPT_NAME"     => "",

          "REQUEST_URI"    => path,
          "PATH_INFO"      => path,
          "HTTP_HOST"      => host,
          "REMOTE_ADDR"    => remote_addr,
          "CONTENT_TYPE"   => "application/x-www-form-urlencoded",
          "CONTENT_LENGTH" => data ? data.length.to_s : nil,
          "HTTP_COOKIE"    => encode_cookies,
          "HTTP_ACCEPT"    => accept,

          "rack.version"      => [0,1],
          "rack.input"        => data,
          "rack.errors"       => StringIO.new,
          "rack.multithread"  => true,
          "rack.multiprocess" => true,
          "rack.run_once"     => false
        )

        (headers || {}).each do |key, value|
          key = key.to_s.upcase.gsub(/-/, "_")
          key = "HTTP_#{key}" unless env.has_key?(key) || key =~ /^HTTP_/
          env[key] = value
        end

        [ControllerCapture, ActionController::ProcessWithTest].each do |mod|
          unless ActionController::Base < mod
            ActionController::Base.class_eval { include mod }
          end
        end

        ActionController::Base.clear_last_instantiation!

        app = Rack::Lint.new(@application)
        status, headers, body = app.call(env)
        @request_count += 1

        @html_document = nil

        @status = status.to_i
        @status_message = StatusCodes::STATUS_CODES[@status]

        @headers = Rack::Utils::HeaderHash.new(headers)

        (@headers['Set-Cookie'] || "").split("\n").each do |cookie|
          name, value = cookie.match(/^([^=]*)=([^;]*);/)[1,2]
          @cookies[name] = value
        end

        @body = ""
        if body.respond_to?(:to_str)
          @body << body
        else
          body.each { |part| @body << part }
        end

        if @controller = ActionController::Base.last_instantiation
          @request = @controller.request
          @response = @controller.response
          @controller.send(:set_test_assigns)
        else
          # Decorate responses from Rack Middleware and Rails Metal
          # as an Response for the purposes of integration testing
          @response = Response.new
          @response.status = status.to_s
          @response.headers.replace(@headers)
          @response.body = @body
        end

        # Decorate the response with the standard behavior of the
        # TestResponse so that things like assert_response can be
        # used in integration tests.
        @response.extend(TestResponseBehavior)

        return @status
      rescue MultiPartNeededException
        boundary = "----------XnJLe9ZIbbGUYtzPQJ16u1"
        status = process(method, path,
          multipart_body(parameters, boundary),
          (headers || {}).merge(
            {"CONTENT_TYPE" => "multipart/form-data; boundary=#{boundary}"}))
        return status
      end
    end
  end
end
