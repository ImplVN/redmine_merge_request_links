class AddLinkedCommentIdToMergeRequests < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :linked_comment_id, :integer
  end
end
