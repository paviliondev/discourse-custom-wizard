# frozen_string_literal: true

class CustomWizard::TagSearch
  def initialize(guardian, params)
    @guardian = guardian
    @params = params
  end

  def results
    tags = DiscourseTagging.filter_allowed_tags(@guardian, **filter_options)
    ::TagsController.tag_counts_json(Tag.with_localizations(tags), @guardian)
  end

  # Tag names from field values, which can be names, tag objects or comma separated text.
  def self.tag_names(value)
    Array
      .wrap(value)
      .flatten
      .filter_map do |tag|
        tag.is_a?(Hash) || tag.is_a?(ActionController::Parameters) ? tag[:name] || tag["name"] : tag
      end
      .flat_map { |tag| tag.to_s.split(",").map(&:strip) }
      .reject(&:blank?)
      .uniq
  end

  # Whether the tag chooser would let the user pick these values.
  def allows?(values, create: false, limit: nil)
    # Compare names as core will save them, e.g. " secret" becomes "secret".
    names = self.class.tag_names(values).map { |name| DiscourseTagging.clean_tag(name).downcase }
    names = names.reject(&:blank?).uniq
    return false if limit.to_i.positive? && names.size > limit.to_i

    existing = Tag.where_name(names).pluck(:name).map(&:downcase)
    return false if !create && (names - existing).any?
    return false if restricted_to_tags? && (existing - allowed_tag_names.map(&:downcase)).any?
    return true if existing.empty?

    # No limit, as tags in several groups can return duplicate rows.
    visible = DiscourseTagging.filter_allowed_tags(@guardian, only_tag_names: existing)
    (existing - visible.map { |tag| tag.name.downcase }).empty?
  end

  private

  def filter_options
    opts = { limit: capped_limit }
    opts[:selected_tag_ids] = selected_tag_ids if selected_tag_ids.present?
    opts[:only_tag_names] = allowed_tag_names if restricted_to_tags?

    if term.present?
      opts[:term] = term
      opts[:order_search_results] = true
    else
      opts[:order_popularity] = true
    end

    opts
  end

  def restricted_to_tags?
    tag_group_names.present? || content_tag_names.present?
  end

  def allowed_tag_names
    (tag_group_tag_names + content_tag_names).uniq
  end

  def tag_group_names
    @tag_group_names ||=
      Array(@params[:tag_groups])
        .flat_map { |names| names.to_s.split(",") }
        .map(&:strip)
        .reject(&:blank?)
  end

  def tag_group_tag_names
    return [] if tag_group_names.blank?

    TagGroup
      .includes(:tags)
      .where(name: tag_group_names)
      .flat_map { |tag_group| tag_group.tags.pluck(:name) }
  end

  def content_tag_names
    @content_tag_names ||= self.class.tag_names(@params[:content])
  end

  def selected_tag_ids
    @selected_tag_ids ||=
      if @params[:selected_tag_ids].present?
        Array(@params[:selected_tag_ids]).map(&:to_i)
      elsif @params[:selected_tags].present?
        Tag.where_name(Array(@params[:selected_tags])).pluck(:id)
      else
        []
      end
  end

  def term
    @term ||= @params[:q].present? ? DiscourseTagging.clean_tag(@params[:q]) : nil
  end

  def capped_limit
    max = SiteSetting.max_tag_search_results
    [@params[:limit].presence&.to_i || max, max].min
  end
end
