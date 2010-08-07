
Running
=======

        git clone git://github.com/goldmann/ct-manager.git
        cd ct-manager
        ruby ct-manager.rb

API description
===============

        GET http://localhost:4567/services
        GET http://localhost:4567/services/SERVICE/status
        GET http://localhost:4567/services/SERVICE/artifacts

        POST http://localhost:4567/services/SERVICE/start
        POST http://localhost:4567/services/SERVICE/stop
        POST http://localhost:4567/services/SERVICE/restart

        POST http://localhost:4567/services/SERVICE/artifacts, params: artifact

        DELETE http://localhost:4567/services/SERVICE/artifacts/ARTIFACT_ID

Dependencies
============

        gem install sinatra dm-core dm-sqlite-adapter dm-migrations