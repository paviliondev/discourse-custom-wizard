# frozen_string_literal: true

module CustomWizardDiscourseTagging
  def filter_allowed_tags(guardian, opts = {})
    if tagGroups = RequestStore.store[:tagGroups]
      tagGroupArray = tagGroups.split(",")
      filtered_tags = TagGroup.includes(:tags).where(name: tagGroupArray).map do |tag_group|
        tag_group.tags.pluck(:name)
      end.flatten

      opts[:only_tag_names] ||= []
      opts[:only_tag_names].push(*filtered_tags)
    end

    super
  end
end
