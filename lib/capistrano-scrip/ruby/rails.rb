# Rails-specific tasks
Capistrano::Configuration.instance.load do
  namespace :deploy do
    desc <<-EOF
    Deploys application for first time - after deploying code it will create database and run +db:seed+, then start
    server

    @note THIS TASK CAN DESTROY YOUR EXISTING DATABASE
    EOF
    task :cold do
      update
      db_setup
      db_seed
      start
    end

    desc <<-EOF
    Runs +rake db:setup+

    @note THIS TASK CAN DESTROY YOUR EXISTING DATABASE
    EOF
    task :db_setup, :roles => :app do
      run "cd #{current_path}; bundle exec rake environment RAILS_ENV=#{rails_env} db:setup"
    end

    desc <<-EOF
    Runs +rake db:seed+
    EOF
    task :db_seed, :roles => :app do
      run "cd #{current_path}; bundle exec rake environment RAILS_ENV=#{rails_env} db:seed"
    end
  end

  before "deploy:finalize_update" do
    if exists? :database_config_path
      run "rm -f #{release_path}/config/database.yml && " \
        "ln -s #{database_config_path} #{release_path}/config/database.yml"
    end
  end
end
