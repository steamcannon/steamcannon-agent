Dependencies
============

        gem install sinatra dm-core dm-sqlite-adapter dm-migrations dm-is-tree json open4 rest-client
        gem install ./gems/thin-1.2.8.gem

Build
-----

        gem install rake echoe

Tests
-----

        gem install rake rspec rcov

Running
=======

        git clone git://github.com/steamcannon/steamcannon-agent.git
        cd steamcannon-agent
        ruby -I lib/ bin/sc-agent -C config/thin/development.yaml start

Tests
-----

        cd steamcannon-agent/spec
        rake

Building
========

To build the gem you need to execute

        rake package

Gem will be placed under pkg/ directory.

API description
===============

        GET http://localhost:4567/services
        GET http://localhost:4567/services/SERVICE/status
        GET http://localhost:4567/services/SERVICE/artifacts

        POST http://localhost:4567/services/SERVICE/start
        POST http://localhost:4567/services/SERVICE/stop
        POST http://localhost:4567/services/SERVICE/restart

        POST http://localhost:4567/services/SERVICE/artifacts, params: artifact
        POST http://localhost:4567/services/SERVICE/configure, params: config

        DELETE http://localhost:4567/services/SERVICE/artifacts/ARTIFACT_ID
