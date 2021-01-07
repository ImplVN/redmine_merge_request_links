require 'net/http'

module RedmineMergeRequestLinks
  module Bot
    class Github
      class PullRequest
        attr_reader :owner, :repo, :id, :bot

        PULL_REQUEST_REGEX = /^https:\/\/github.com\/(.+)\/(.+)\/pull\/(\d+)$/

        def initialize(merge_request, bot)
          url = merge_request.url
          _, @owner, @repo, @id = url.match(PULL_REQUEST_REGEX).to_a
          @bot = bot
        end

        def comments
          request("/issues/#{id}/comments") do |uri|
            Net::HTTP::Get.new(uri)
          end
        end

        def delete_comment(comment_id)
          request("/issues/comments/#{comment_id}") do |uri|
            Net::HTTP::Delete.new(uri)
          end
        end

        def update_comment(comment_id, body)
          request("/issues/comments/#{comment_id}") do |uri|
            Net::HTTP::Patch.new(uri, { 'Content-Type' => 'application/json' }).tap do |req|
              req.body = { body: body }.to_json
            end
          end
        end

        def create_comment(body)
          request("/issues/#{id}/comments") do |uri|
            Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' }).tap do |req|
              req.body = { body: body }.to_json
            end
          end
        end

        private

        def request(path)
          uri = URI("https://api.github.com/repos/#{owner}/#{repo}#{path}")
          Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            request = yield uri
            request.basic_auth bot.username, bot.password
            Rails.logger.debug(request.class.name)

            response = http.request request
            Rails.logger.debug("https://api.github.com/repos/#{owner}/#{repo}#{path}")
            Rails.logger.debug(response.class.name)
            JSON.parse(response.body) rescue nil
          end
        end
      end

      attr_reader :username, :password

      def initialize(username:, password:)
        @username = username
        @password = password
      end

      def update_attached_redmine_urls(merge_request)
        pull_request = PullRequest.new(merge_request, self)
        bot_comment = pull_request.comments.find do |comment|
          comment.dig("user", "login") == username
        end

        if bot_comment.present?
          if merge_request.issues.any?
            pull_request.update_comment(bot_comment["id"], comment_content(merge_request.issues))
          else
            pull_request.delete_comment(bot_comment["id"])
          end
        else
          if merge_request.issues.any?
            pull_request.create_comment(comment_content(merge_request.issues))
          end
        end
      end

      def matches?(merge_request)
        merge_request.provider == 'github'
      end

      private

      def comment_content(issues)
        title = "#### Redmine links:"
        issue_urls = issues.map do |issue|
          url = Rails.application.routes.url_helpers.issue_url(issue, host: ENV.fetch("REDMINE_BASE_URL"))
          "- #{url}"
        end
        [title, *issue_urls].join("\n")
      end
    end
  end
end
