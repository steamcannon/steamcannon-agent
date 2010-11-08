Dependencies
============

        gem install bundler
        bundle install

Running
=======

        git clone git://github.com/steamcannon/steamcannon-agent.git
        cd steamcannon-agent
        thin -C config/thin/local.yaml start

Tests
=====

        cd steamcannon-agent/spec
        rake

API description
===============

        GET http://localhost:7575/services
        GET http://localhost:7575/services/SERVICE/status
        GET http://localhost:7575/services/SERVICE/artifacts

        POST http://localhost:7575/services/SERVICE/start
        POST http://localhost:7575/services/SERVICE/stop
        POST http://localhost:7575/services/SERVICE/restart

        POST http://localhost:7575/services/SERVICE/artifacts, params: artifact
        POST http://localhost:7575/services/SERVICE/configure, params: config

        DELETE http://localhost:7575/services/SERVICE/artifacts/ARTIFACT_ID
