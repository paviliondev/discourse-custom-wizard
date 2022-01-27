# frozen_string_literal: true

module ::DiscourseTagging
  class << self
    alias_method :discourse_core_filter_allowed_tags, :filter_allowed_tags
    def filter_allowed_tags(guardian, opts = {})
      if tagGroups = RequestStore.store[:tagGroups]
        tagGroupArray = tagGroups.split(",")
        filtered_tags = TagGroup.includes(:tags).where(name: tagGroupArray).map do |tag_group|
          tag_group.tags.pluck(:name)
        end.flatten

        opts[:only_tag_names] ||= []
        opts[:only_tag_names].push(*filtered_tags)
      end

      discourse_core_filter_allowed_tags(guardian, opts)
    end
  end
end
