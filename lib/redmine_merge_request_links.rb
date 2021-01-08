require 'redmine_merge_request_links/hooks'

module RedmineMergeRequestLinks
  github_token = ENV['REDMINE_MERGE_REQUEST_LINKS_GITHUB_WEBHOOK_TOKEN']
  gitlab_token = ENV['REDMINE_MERGE_REQUEST_LINKS_GITLAB_WEBHOOK_TOKEN']
  gitea_token  = ENV['REDMINE_MERGE_REQUEST_LINKS_GITEA_WEBHOOK_TOKEN']

  mattr_accessor :event_handlers, :bots

  self.event_handlers = [
    RedmineMergeRequestLinks::EventHandlers::Gitea.new(token: gitea_token),
    RedmineMergeRequestLinks::EventHandlers::Github.new(token: github_token),
    RedmineMergeRequestLinks::EventHandlers::Gitlab.new(token: gitlab_token)
  ]

  github_bot_username = ENV["REDMINE_MERGE_REQUEST_LINKS_GITHUB_USERNAME"]
  github_bot_password = ENV["REDMINE_MERGE_REQUEST_LINKS_GITHUB_PASSWORD"]
  self.bots = [
    RedmineMergeRequestLinks::Bot::Github.new(username: github_bot_username, password: github_bot_password)
  ]
end
