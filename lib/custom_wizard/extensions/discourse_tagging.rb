# frozen_string_literal: true
require 'request_store'

module CustomWizardDiscourseTagging
  def filter_allowed_tags(guardian, opts = {})
    if tag_groups = ::RequestStore.store[:tag_groups]
      tag_group_array = tag_groups.split(",")
      filtered_tags = TagGroup.includes(:tags).where(name: tag_group_array).map do |tag_group|
        tag_group.tags.pluck(:name)
      end.flatten

      opts[:only_tag_names] ||= []
      opts[:only_tag_names].push(*filtered_tags)
    end

    super
  end
end
