# Hydrus
[![Build Status](https://travis-ci.com/sul-dlss/hydrus.svg?branch=master)](https://travis-ci.com/sul-dlss/hydrus)
[![Test Coverage](https://api.codeclimate.com/v1/badges/4f81c285af8b8889c9f4/test_coverage)](https://codeclimate.com/github/sul-dlss/hydrus/test_coverage)

## Overview

A Hydra application enabling deposit of digital objects into the Stanford
Digital Repository for preservation and access.

## Setting up your environment

### System Requirements

1. Install Docker
2. Install Ruby (version per travis CI config)

## Run the servers

```
docker-compose up -d
```


```bash
brew install exiftool # Required by assembly-objectfile

./bin/rails db:migrate db:test:prepare

RAILS_ENV=test ./bin/rails hydrus:refreshfix # load all fedora and database fixtures, and get sample uploaded files
```

## Running the application

You can provide the current user and roles using environment variables when the server is in development mode:

```bash
ROLES=dlss:hydrus-app-administrators REMOTE_USER=archivist1@stanford.edu rails server
```

## Useful URLs during development

* Hydrus - [http://localhost:3000](http://localhost:3000)
* Fedora admin - [http://localhost:8983/fedora/admin](http://localhost:8983/fedora/admin)
* Fedora objects - [http://localhost:8983/fedora/objects](http://localhost:8983/fedora/objects)
* Solr - [http://localhost:8984/solr](http://localhost:8984/solr)

## Running tests

To run the test suite, invoke `rake` from the Hydrus app root. Note that the docker containers need to be running already for this work.

```bash
$ rake # Runs all tests.

# Coverage reports
$ open coverage/index.html
```

If you encounter problems with running tests, try:

```bash
$ docker-compose stop
$ docker-compose rm -vf
$ docker-compose up -d
```


## Deployment


```bash
cap [stage_name] deploy
```

Run remediations the objects in the deployed environment require changes to be consistent with the new code.

1. Shut down the application.
2. Run remediations: see section below.
3. Start the application.

## Remediations

The general framework, and the front-end.  See the code for more details on how the process works.

    app/models/hydrus/remediation_runner.rb
    remediations/run.rb

Remediation scripts:
- Stored in the remediations subdirectory.
- Naming following the application version naming convention:
  - 2013.02.25a.rb
  - 2013.02.27a.rb
  - 2013.02.27b.rb
  - etc.
- See `remediations/archive/0000.00.00a.rb` for a schematic example.
- After remediations are run on all deployed environments, they typically won't be needed in the future, so they can be moved in the Git repo into the remediations/archive directory.

Running remediations (using production environment as the example):

```bash
# Must run from the deployed box.
RAILS_ENV=production bundle exec rails runner remediations/run.rb
grep -i warn log/remediation.log  #Then search for problems.
```

## Useful commands

List the Hydrus rake tasks.

    rake -T hydrus

Some handy scripts during development.

    rails runner devel/create_test_item.rb help
    rails runner script/experiment.rb         # See comments in script.
    rails runner devel/get_datastreams.rb
    rails runner devel/list_all_hydrus_objects.rb

## Misc

If you see an error relating to generate_intial_workflow() for nil:NilClass,
run this:

    rake hydrus:reindex_workflow_objects


## Terms of deposit text

If you update the text, you should change the following:

Headings:

* `app/views/hydrus_items/terms_of_deposit.html.erb`
* `app/views/hydrus_items/_terms_of_deposit_popup.html.erb`

Text and headings:

* `app/views/hydrus_items/_terms_of_deposit_text.html.erb`
* `doc/SDRSelfDepositTerms.doc`
* `$public/SDRSelfDepositTerms.pdf`

## Workflow steps and object_status

General points:

* The Hydrus application advances an object through the steps of the
  hydrusAssemblyWF. However, the application does not consult the
  hydrusAssemblyWF for information.
* Instead, the application consults hydrusProperty for all information
  related to the status of an object and its flow through the steps in the
  Hydrus deposit process.
* Because they have somewhat different purposes, the hydrusAssemblyWF steps
  and the Hydrus object_status values do not have a one-to-one
  correspondence.
* Whereas a workflow is designed to move only in the forward direction as
  various steps are accomplished, Hydrus object_status can toggle back and
  forth between various states during the edit-and-review and
  collection-open-and-close processes.
* Hydrus does consult the workflow service when it needs information about
  the status of an object in assemblyWF and accessionWF. The primary
  examples are in the is_accessioned() and publish_time() methods.


Relationship between object_status and workflow steps for collections:

    object_status              workflow steps
    ----------------------------------------------------
    draft                      start-deposit

    published_open             submit --> approve --> start-assembly

    published_closed           start-assembly
    ----------------------------------------------------

Notes:
- The first time a collection is opened, it automatically advances through a
  few workflow steps.
- After that, the collection manager can toggle the collection between open
  and closed states, but the collection cannot be unpublished and the
  workflow steps do not move backward.
- Typically the application is configured not to start assembly in local
  development mode. Thus the object remains as the "approve" workflow step
  rather than "start-assembly".

Relationship between object_status and workflow steps for items:

    Items not requiring human approval:

    object_status              workflow steps
    ----------------------------------------------------
    draft                      start-deposit
    published                  submit --> approve --> start-assembly
    ----------------------------------------------------

    Items requiring human approval:

    object_status              workflow steps
    ----------------------------------------------------
    draft                      start-deposit
    awaiting_approval          submit
    returned                   submit
    published                  approve --> start-assembly
    ----------------------------------------------------

Note: Items can toggle back and forth between awaiting_approval and returned
during the edit-and-review process. During that time, the workflow remains at the submit step.

## Creating a Hydrus Item with a particular PID

```ruby
# Temporarily edit register_dor_object().
params[:pid] = 'ITEM_PID' if args.last == 'APO_PID'

# Run this in the Rails console.
bundle exec rails c ENV
hc = Hydrus::Collection.find 'COLL_PID'
u  = User.new(:email => 'EMAIL')
hi = ItemService.create(hc.pid, u)
```

## Manually Adding a File to an Existing Object

1. Move the file(s) to the `/data/hydrus-files/tmp` folder on the hydrus-prod server using sftp or some other mechanism
2. SSH into the hydrus-prod server, go to the app directory and start a console
```bash
cd hydrus/current
bundle exec rails console production
```
3. Now from the Rails console add your file(s) to the object by creating new ObjectFile(s)
```ruby
hof = Hydrus::ObjectFile.new
hof.pid   = 'druid:XX111YY2222'
hof.hide  = false               # set this to true if the file should be hidden (default: false)
hof.label = "Description"       # optional description of file, can be left blank
hof.file  = File.open('/data/hydrus-files/tmp/YOURFILENAME')  # add your file here by path
hof.save  # should return true if it succeeded
```
4. Repeat step 3 for any additional files
5. Refresh the object page in hydrus to confirm the files are listed.  You can also double-check that the files were placed in the correct location, `/data/hydrus-files/DRUID/TREE/PATH/DRUID/content`
    e.g. `/data/hydrus-files/xx/111/yy/2222/xx111yy2222/content`
6. Delete the files from the */data/hydrus-files/tmp* directory
