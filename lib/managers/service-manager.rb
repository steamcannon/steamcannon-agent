require 'singleton'
require 'helpers/config-helper'

def service( args )
  ServiceManager.instance.register_service( args )
end

class ServiceManager
  include Singleton

  def initialize
    @services = {}
    @config   = ConfigHelper.instance.config
  end

  def register_service( args )
    if @services[args[:name]].nil? and @config['services'].include?( args[:name].to_s )
      clazz = args[:class]
      args.delete( :class )

      clazz.send(:define_method, :supported_operations ) { { :operation => 'supported_operations', :status => 'ok', :response =>  (self.public_methods - Object.public_methods).sort }}

      @services[args[:name]] = { :object => clazz.new, :info => args }
    end
  end

  def execute_operation( name, operation, *params )
    service = @services[name.to_sym][:object]

    unless service.respond_to?( operation )
      return { :operation => operation, :status => 'error', :message => "Operation '#{operation}' is not supported in #{service.class} service"}
    end

    if service.method( operation ).arity != params.size and service.method( operation ).arity >= 0
      return { :operation => operation, :status => 'error', :message => "Operation '#{operation}' takes #{service.method( operation ).arity } argument, but provided #{params.size}"}
    end

    service.send( operation, *params )
  end

  def service_exists?( name )
    !@services[name.to_sym].nil?
  end

  def services_info
    info = []

    @services.values.each do |service|
      info << service[:info]
    end

    info
  end

  attr_reader :services
end

