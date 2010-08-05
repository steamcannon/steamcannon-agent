class JBossASService
  def restart
    { :operation => 'restart', :status => 'ok' }
  end

  def start
    { :operation => 'start', :status => 'ok' }
  end

  def stop
    { :operation => 'stop', :status => 'ok' }
  end

  def status
    # started, stopped, starting, stopping
    { :operation => 'status', :status => 'ok', :response => 'started' }
  end

  def artifacts
    {:operation => 'artifacts', :status => 'ok', :response => [ { :id => 12, :type => 'war', :name => 'My app' }, { :id => 14, :type => 'ear', :name => 'My business app' } ] }
  end

  def deploy( artifact )
    # validate the parameter, do the job, etc

    { :operation => 'deploy', :status => 'ok', :artifact_id => 1 }
  end

  def undeploy( artifact_id )
    # validate the parameter, do the job, etc

    { :operation => 'undeploy', :status => 'ok' }
  end

  def configure( file, path ) # ???
    # validate the parameter, do the job, etc

    { :operation => 'configure', :status => 'ok' }
  end
end

service :name => :jboss_as, :full_name => 'JBoss Application Server', :class => JBossASService