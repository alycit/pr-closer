require 'octokit'
require 'io/console'

def display_welcome
  puts "Welcome to the PR Closer for DBC Student Code Review Requests!"
  puts "This will close all open pull requests which you were mentioned in that were created before the date you specify."
  puts "This only closes PRs that end in a year '-YYYY' as per the cohort slug."
end

def client_login
  print "Enter your github id: "
  login = gets.chomp!
  print "Enter your github password: "
  password = STDIN.noecho(&:gets).chomp!

  begin
    client = Octokit::Client.new(login: login, password: password)
    puts "You have been authenticated #{client.user.name}."
    client
  rescue Exception => e
    abort "ABORTING: Error logging in: #{e.message}"
  end
end

def determine_date
  print "Enter a date. Only open PRs before this date will be closed (YYYY-MM-DD): "
  date = gets.chomp!
  abort "ABORTING: Invalid or No date entered" if date.nil? || !/\d{4}-\d{2}-\d{2}/.match(date)
  date
end

def closeable_pr?(pr_url)
  pr_url.include?("-2014") || pr_url.include?("-2015") || pr_url.include?("-2016")
end

def close_pr(client, pr_url)
  match = /^\S+repos\/(\S+)\/issues\/(\d+)$/.match(pr_url)

  begin
    status = client.close_pull_request(match[1], match[2].to_i)
    puts "pr closed: #{pr_url}" if status.state == "closed"
    sleep 1 # just to hopefully not hit rate limit
  rescue Exception => e
    puts "Unable to close #{pr_url}: #{e.message}"
  end
end

def process_prs(client, date)
  loop do
    begin
      # search has a rate limit of 30 requests per minute https://developer.github.com/v3/search/
      items = client.search_issues("mentions:#{client.user.login} is:open is:pr created:<=#{date}", {order: "asc", sort: "created", per_page: 100}).items
      puts "No PRs to Process" if items.empty?

      break if items.empty?

      items.each do |item|
        if closeable_pr?(item.url)
          close_pr(client, item.url)
        end
      end
    rescue Exception => e
      abort "ABORTING: -Unable to search for open PRs: #{e.message}"
    end
  end
end

display_welcome
process_prs(client_login, determine_date)





