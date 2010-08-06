require 'services/base-service'

class JBossASService < BaseService
  def initialize
    register_service( :jboss_as, 'JBoss Application Server' )
  end

  def restart
    { :operation => 'restart', :status => 'ok' }
  end

  def start
    @log.info "Starting JBoss AS..."

    # actual code

    @log.info "JBoss is starting..."

    { :operation => 'start', :status => 'ok', :response => { :jboss_status => :starting } }
  end

  def stop
    { :operation => 'stop', :status => 'ok', :response => { :jboss_status => :stopping } }
  end

  def status
    # started, stopped, starting, stopping
    { :operation => 'status', :status => 'ok', :response => { :jboss_status => :started } }
  end

  def artifacts
    { :operation => 'artifacts', :status => 'ok', :response => [ { :id => 12, :type => 'war', :name => 'My app' }, { :id => 14, :type => 'ear', :name => 'My business app' } ] }
  end


  def deploy( artifact )
    # validate the parameter, do the job, etc

    { :operation => 'deploy', :status => 'ok', :response => { :artifact_id => 1 } }
  end

  def undeploy( artifact_id )
    # validate the parameter, do the job, etc

    { :operation => 'undeploy', :status => 'ok' }
  end

end