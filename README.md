
Running
=======

        git clone git://github.com/goldmann/ct-manager.git
        cd ct-manager
        ruby ct-manager.rb

Try those URLs:

GET http://localhost:4567/services
GET http://localhost:4567/services/jboss_as/supported_operations
GET http://localhost:4567/services/jboss_as/status
GET http://localhost:4567/services/jboss_as/artifacts

POST http://localhost:4567/services/jboss_as/stop
POST http://localhost:4567/services/jboss_as/restart
POST http://localhost:4567/services/jboss_as/artifacts/deploy

Dependencies
============

gem install sinatra dm-core dm-sqlite-adapter db-migrations