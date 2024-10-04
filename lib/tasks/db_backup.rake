namespace :db do
  task :backup => :environment do
    time = Time.current
    tar = "/var/www/octoshell2/shared/db_backups/#{time.strftime('%Y%m%d_%H%M')}.tar"
    system "pg_dump -f #{tar} -U octo -h 127.0.0.1 -F tar new_octoshell"
    system "bzip2 #{tar}"
  end
end
#29 0 * * * /bin/bash -l -c 'cd /var/www/octoshell2/current/ && date >> /var/www/octoshell2/shared/log/cron.log && RAILS_ENV=production nice -n 20 ionice -c3 rbenv exec bundle exec rake db:backup >> /var/www/octoshell2/shared/log/cron.log 2>&1'
