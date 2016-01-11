require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = route_params.merge(req.params)
    @already_built_response = false
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    raise 'no double rendering' if already_built_response?
    @res.status = 302
    @res['Location'] = url
    @already_built_response = true
    session.store_session(res)

    nil
  end

  def render_content(content, content_type)
    raise 'no double rendering' if already_built_response?
    @res['Content-Type'] = content_type
    @res.write(content)
    @already_built_response = true
    session.store_session(res)

    nil
  end

  def render(template_name)
    path = "views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    file = File.read(path)
    template = ERB.new(file).result(binding)
    render_content(template, 'text/html')
  end

  def session
    @session ||= Session.new(req)
  end

  def invoke_action(name)
    self.send(name.to_sym)
    render(name) unless @already_built_response
  end
end
