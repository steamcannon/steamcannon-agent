Dependencies
============

        gem install sinatra dm-core dm-sqlite-adapter dm-migrations json open4
        gem install ./gems/thin-1.2.8.gem

Tests
-----

        gem install rake rspec rcov

Running
=======

        git clone git://github.com/goldmann/ct-manager.git
        cd ct-manager
        ruby -I lib/ bin/agent -C config/thin/development.yaml start

Tests
-----

        cd ct-manager/spec
        rake

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
