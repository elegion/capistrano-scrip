Capistrano::Configuration.instance.load do
  namespace :south do
    _cset(:python) { "python" }

    task :syncdb do
      run "#{python} #{latest_release}/manage.py syncdb --noinput --migrate"
    end
    task :migrate do
      run "#{python} #{latest_release}/manage.py migrate --noinput"
    end
  end

  namespace :deploy do
    task :migrations do
      transaction do
        deploy.update_code
        south.syncdb
        deploy.symlink
      end
    end
  end

  after 'deploy:cold', 'south:syncdb'
end
