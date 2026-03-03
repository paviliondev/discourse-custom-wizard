# frozen_string_literal: true

module CustomWizardDiscourseTagging
  def filter_allowed_tags(guardian, opts = {})
    normalize_selected_tags!(opts)

    if opts[:for_input].respond_to?(:dig) && (groups = opts.dig(:for_input, :groups)).present?
      tag_group_array = groups.split(",")
      filtered_tags =
        TagGroup
          .includes(:tags)
          .where(name: tag_group_array)
          .map { |tag_group| tag_group.tags.pluck(:name) }
          .flatten

      opts[:only_tag_names] ||= []
      opts[:only_tag_names].push(*filtered_tags)
      opts.delete(:for_input)
    end

    super
  end

  private

  def normalize_selected_tags!(opts)
    selected_tags = opts[:selected_tags]
    return if selected_tags.blank?

    selected_tag_ids = Array(opts[:selected_tag_ids])
    normalized_selected_tags = []

    selected_tags = selected_tags.values if selected_tags.respond_to?(:values)

    Array(selected_tags).each do |selected_tag|
      name, selected_tag_id = extract_selected_tag(selected_tag)

      normalized_selected_tags << name if name.present?
      selected_tag_ids << selected_tag_id.to_i if selected_tag_id.present?
    end

    opts[:selected_tags] = normalized_selected_tags
    opts[:selected_tag_ids] = selected_tag_ids
  end

  def extract_selected_tag(selected_tag)
    case selected_tag
    when String
      [selected_tag, nil]
    when Symbol
      [selected_tag.to_s, nil]
    when Numeric
      [nil, selected_tag]
    when Hash, ActionController::Parameters
      [selected_tag[:name] || selected_tag["name"], selected_tag[:id] || selected_tag["id"]]
    else
      [nil, nil]
    end
  end
end
