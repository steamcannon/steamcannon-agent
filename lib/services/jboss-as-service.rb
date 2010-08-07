require 'services/base-service'

class JBossASService < BaseService
  def initialize
    register_service( :jboss_as, 'JBoss Application Server' )

    @jboss_home             = '/opt/jboss-as'
    @default_configuration  = 'default'
    @service_name           = 'jboss-as6'
  end

  def restart
    @db.save_event( :restart, :received )

    manage_service( :restart )

    @log.info "JBoss AS is restarting..."

    { :status => 'ok', :response => { :status => :restarting } }
  end

  def start
    @db.save_event( :start, :received )

    manage_service( :start )

    @log.info "JBoss AS is starting..."

    { :status => 'ok', :response => { :status => :starting } }
  end

  def stop
    @db.save_event( :stop, :received )

    manage_service( :stop )

    @log.info "JBoss AS is stopping..."

    { :status => 'ok', :response => { :status => :stopping } }
  end

  def status
    # started, stopped, starting, stopping
    { :status => 'ok', :response => { :status => :started } }
  end

  def artifacts

    artifacts = []

    @db.artifacts.each do |artifact|
      artifacts << { :name => artifact.name, :id => artifact.id }
    end

    { :status => 'ok', :response => artifacts }
  end

  def deploy( artifact )
    @db.save_event( :deploy, :received )

    #TODO base 64 decode artifact
    # validate the parameter, do the job, etc
    # Tempfile
    # FileUtils.cp( tempfile, "#{@jboss_home}/server/#{@default_configuration}/deploy/" )

    name = 'abc.war'

    if a = @db.save_artifact( :name => name, :location => "#{@jboss_home}/server/#{@default_configuration}/deploy/#{name}" )
      @db.save_event( :deploy, :finished )
      { :status => 'ok', :response => { :artifact_id => a.id } }
    else
      @db.save_event( :deploy, :failed )
      { :status => 'error', :msg => "Error while saving artifact" }
    end
  end

  def undeploy( artifact_id )
    @db.save_event( :undeploy, :received )

    # TODO: remove artifact from JBoss

    if @db.remove_artifact( artifact_id )
      @db.save_event( :undeploy, :finished )
      { :status => 'ok' }
    else
      @db.save_event( :undeploy, :failed )
      { :status => 'error', :msg => "Error occurred while removing artifact with id = '#{artifact_id}'" }
    end
  end

  protected

  def manage_service( operation )
    Thread.new do
      @log.info "Trying to #{operation} '#{@service_name}' service..."
      begin
        @exec_helper.execute( "service #{@service_name} #{operation}" )
        @db.save_event( operation, :finished )
        @log.info "#{operation} operation executed on service #{@service_name}"
      rescue
        @db.save_event( operation, :failed )
      end
    end
  end

end