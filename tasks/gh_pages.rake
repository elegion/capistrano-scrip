desc 'Generates documentation'
task :gh_pages do
  sh 'cd doc/ && git checkout gh-pages && git reset --hard origin/gh-pages && git pull origin gh-pages'
  Rake::Task["yard"].invoke
  sh 'cd doc/ && git add . && git commit -m "Updating docs" && git push origin gh-pages'
end
