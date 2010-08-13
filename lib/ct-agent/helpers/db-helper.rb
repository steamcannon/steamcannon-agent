require 'logger'
require 'ct-agent/models/artifact'

class DBHelper
  def initialize( service, options = {} )
    @service  = service
    @log      = options[:log] || Logger.new(STDOUT)
  end

  def save_artifact( artifact )
    return false unless artifact.is_a?(Hash)

    artifact[:service] = @service

    begin
      return Artifact.create( artifact )
    rescue => e
      @log.error e.backtrace
      false
    end
  end

  def remove_artifact( artifact_id )
    a =  artifact( artifact_id )

    return false unless a

    begin
      a.destroy
      return true
    rescue => e
      @log.error e.backtrace
      false
    end
  end

  def artifacts
    begin
      return Artifact.all( :service => @service )
    rescue => e
      @log.error e.backtrace
      false
    end
  end

  def artifact( id )
    begin
      return Artifact.get( id )
    rescue => e
      @log.error e.backtrace
      false
    end
  end

  def save_event( operation, status )
    begin
      return Event.create( :operation => operation, :status => status, :service => @service )
    rescue => e
      @log.error e.backtrace
      false
    end
  end
end