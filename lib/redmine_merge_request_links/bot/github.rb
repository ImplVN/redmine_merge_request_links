require 'net/http'

module RedmineMergeRequestLinks
  module Bot
    class Github
      attr_reader :username, :password

      def initialize(username:, password:)
        @username = username
        @password = password
      end

      def update_attached_redmine_urls(merge_request)
        pull_request = Github::RemoteMergeRequest.new(merge_request, self)
        is_bot_commented = merge_request.linked_comment_id.present?

        if is_bot_commented && merge_request.issues.any?
          pull_request.update_comment(merge_request.linked_comment_id, comment_content(merge_request.issues))
          return merge_request.linked_comment_id
        end

        if is_bot_commented && merge_request.issues.empty?
          pull_request.delete_comment(merge_request.linked_comment_id)
          return nil
        end

        if !is_bot_commented && merge_request.issues.any?
          new_comment = pull_request.create_comment(comment_content(merge_request.issues))
          return new_comment["id"]
        end

        merge_request.linked_comment_id
      end

      def matches?(merge_request)
        merge_request.provider == 'github'
      end

      private

      def comment_content(issues)
        title = "#### Redmine tickets:"
        issue_urls = issues.map do |issue|
          url = Rails.application.routes.url_helpers.issue_url(issue, host: ENV.fetch("REDMINE_BASE_URL"))
          "- #{url}"
        end
        [title, *issue_urls].join("\n")
      end
    end
  end
end
