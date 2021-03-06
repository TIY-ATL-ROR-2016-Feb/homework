require "pry"
require "httparty"

require "homework/version"
require "homework/pass"
require "homework/github"

module Homework
  class App
    def initialize
      @github = Github.new
    end

    def prompt(message, regex)
      puts message
      choice = gets.chomp
      until choice =~ regex
        puts "Incorrect input. Try again."
        puts message
        choice = gets.chomp
      end
      choice
    end

    def confirm?(msg)
      puts msg
      answer = prompt("Are you sure you want to do that?", /^[yn]$/)
      answer == "y"
    end

    # def dumb_example
    #   dumb_thing_a
    #   sensible_thing_b
    #   dumb_thing_c
    # rescue TerribleError => e
    #   puts "Saved the world"
    # rescue OtherTerribleThing => e
    #   puts "oh shit"
    # end

    def assign_homework
      org_name = prompt("What Github Org are you a member of?",
                        /^[a-z0-9\-]{4,30}$/i)
      hw_repo = prompt("What Github repo do you assign homework to?",
                       /^[a-z0-9\-\_]{6,20}$/i)
      team_name = prompt("What team are your students members of?",
                         /^[a-zA-Z]{4,20}/)

      binding.pry
      begin
        students = @github.list_members_by_team_name(org_name, team_name)
        students.each do |student|
          username = student["login"]
          @github.create_issue(org_name, hw_repo, "Close this Issue plz", assignee: username, body: contents_of_gist)
        end
      rescue InsufficientAccessError => e
        puts e.message
        puts "If you're using an OAuth token make sure to enable Organization scopes."
      rescue SocketError => e
        puts e.message
        puts "Your internet connection is in jeopardy. Please seek help."
      end
    end
  end
end

homework = Homework::App.new
homework.assign_homework
