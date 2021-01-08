module RedmineMergeRequestLinks
  module Bot
    class Github
      class RemoteMergeRequest
        attr_reader :owner, :repo, :id, :credentials

        PULL_REQUEST_REGEX = /^https:\/\/github.com\/(.+)\/(.+)\/pull\/(\d+)$/

        def initialize(merge_request, credentials)
          url = merge_request.url
          _, @owner, @repo, @id = url.match(PULL_REQUEST_REGEX).to_a
          @credentials = credentials
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
            request.basic_auth credentials.username, credentials.password
            Rails.logger.debug(request.class.name)

            response = http.request request
            Rails.logger.debug("https://api.github.com/repos/#{owner}/#{repo}#{path}")
            Rails.logger.debug(response.class.name)
            JSON.parse(response.body) rescue nil
          end
        end
      end
    end
  end
end
