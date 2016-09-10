require 'octokit'
require 'io/console'

def closeable_pr?(pr_url)
  pr_url.include?("-2014") || pr_url.include?("-2015") || pr_url.include?("-2016")
end

puts "Welcome to the PR Closer for DBC Student Code Review Requests!"
puts "This will close all open pull requests which you were mentioned in that were created before the date you specify."
puts "This only closes PRs that end in a year '-YYYY' as per the cohort slug."
puts

print "Enter your github id: "
login = gets.chomp!
print "Enter your github password: "
password = STDIN.noecho(&:gets).chomp!

client = Octokit::Client.new(login: login, password: password)
user = client.user

puts
puts
puts "You have been authenticated #{user.login}."
puts

print "Enter a date. Only open PRs before this date will be closed (YYYY-MM-DD): "
date = gets.chomp!

results = client.search_issues("mentions:#{user.login} is:open is:pr created:<=#{date}", {order: "asc", sort: "created", per_page: 100})

puts
puts "Only 1000 closable at a time."
puts "Total number to close: #{results.total_count}"


10.times do |page_number|
  results = client.search_issues("mentions:#{user.login} is:open is:pr created:<=#{date}", {order: "asc", sort: "created", page: page_number, per_page: 100})

  results.items.each do |item|
    if closeable_pr?(item.url)
      puts "closing this pr: #{item.url}"
    end
    sleep 0.25
  end
end





