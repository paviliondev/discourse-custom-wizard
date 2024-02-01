# frozen_string_literal: true

module CustomWizardDiscourseTagging
  def filter_allowed_tags(guardian, opts = {})
    if opts[:for_input].respond_to?(:dig) && (groups = opts.dig(:for_input, :groups)).present?
      tag_group_array = groups.split(",")
      filtered_tags = TagGroup.includes(:tags).where(name: tag_group_array).map do |tag_group|
        tag_group.tags.pluck(:name)
      end.flatten

      opts[:only_tag_names] ||= []
      opts[:only_tag_names].push(*filtered_tags)
    end

    super
  end
end
