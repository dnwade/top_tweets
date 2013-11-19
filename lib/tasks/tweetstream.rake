namespace :twitter do
  desc 'streaming sample'
  task :sample => :environment do
    TweetStream::Client.new.sample do |status, client|
      puts "#{status.user.name} :: #{status.full_text}"
    end
  end

  desc 'simple tracking'
  task :track => :environment do
    TweetStream::Daemon.new('tracker').track('nfl', 'brady') do |status|
      binding.pry
    end
  end
end
