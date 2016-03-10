module Homework
  class Github
    include HTTParty
    base_uri "https://api.github.com"

    def initialize
      @headers = {
        "Authorization" => "token #{ENV["OAUTH_TOKEN"]}",
        "User-Agent"    => "HTTParty"
      }
    end

    def get_user(username)
      Github.get("/users/#{username}", headers: @headers)
    end

    def list_members_by_team_name(org, team_name)
      teams = list_teams(org)
      if teams.headers["X-ratelimit-remaining"].zero?
        raise RateLimitError, "You're out of requests until #{Time.at(teams.headers["X-ratelimit-reset"])}!"
      end
      if teams.code == 403
        raise InsufficientAccessError, "Your access credentials for Github were insufficient."
      end
      team = teams.find { |t| t["name"] == team_name }
      list_team_members(team["id"])
    end

    def list_issues(owner, repo)
      Github.get("/repos/#{owner}/#{repo}/issues", headers: @headers)
    end

    def comment_issue(owner, repo, issue_num, comment)
      Github.post("/repos/#{owner}/#{repo}/issues/#{issue_num}/comments",
                  headers: @headers, body: {"body" => comment}.to_json)
    end

    def close_issue(owner, repo, issue_num)
      Github.patch("/repos/#{owner}/#{repo}/issues/#{issue_num}",
                   headers: @headers, body: {"state" => "closed"}.to_json)
    end

    def get_gist(id)
      Github.get("/gists/#{id}", headers: @headers)
    end

    # def create_issue(owner, repo, title)
    #   Github.post("/repos/#{owner}/#{repo}/issues", headers: @headers, body: {"title" => title}.to_json)
    # end

    def create_issue(owner, repo, title, options={})
      params = options.merge({"title" => title}).to_json
      Github.post("/repos/#{owner}/#{repo}/issues", headers: @headers,
                  body: params)
    end


    private


    def list_teams(organization)
      Github.get("/orgs/#{organization}/teams", headers: @headers)
    end

    def list_team_members(team_id)
      Github.get("/teams/#{team_id}/members", headers: @headers)
    end
  end

  class InsufficientAccessError < StandardError
  end

  class RateLimitError < StandardError
  end
end
